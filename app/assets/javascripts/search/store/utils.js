import { isEqual, orderBy, isEmpty } from 'lodash';
import AccessorUtilities from '~/lib/utils/accessor';
import { formatNumber } from '~/locale';
import { joinPaths, queryToObject, objectToQuery, getBaseURL } from '~/lib/utils/url_utility';
import {
  LABEL_AGREGATION_NAME,
  LANGUAGE_FILTER_PARAM,
  SCOPE_BLOB,
} from '~/search/sidebar/constants';
import {
  MAX_FREQUENT_ITEMS,
  MAX_FREQUENCY,
  SIDEBAR_PARAMS,
  NUMBER_FORMATING_OPTIONS,
  REGEX_PARAM,
  LS_REGEX_HANDLE,
} from './constants';

function extractKeys(object, keyList) {
  return Object.fromEntries(keyList.map((key) => [key, object[key]]));
}

export const loadDataFromLS = (key) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return null;
  }

  try {
    return JSON.parse(localStorage.getItem(key)) || null;
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return null;
  }
};

export const setDataToLS = (key, value) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return null;
  }

  try {
    localStorage.setItem(key, JSON.stringify(value));
    return value;
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return null;
  }
};

export const setFrequentItemToLS = (key, data, itemData) => {
  if (!AccessorUtilities.canUseLocalStorage()) {
    return [];
  }

  const keyList = [
    'id',
    'avatar_url',
    'name',
    'full_name',
    'name_with_namespace',
    'frequency',
    'lastUsed',
  ];

  try {
    const frequentItems = data[key].map((obj) => extractKeys(obj, keyList));
    const item = extractKeys(itemData, keyList);
    const existingItemIndex = frequentItems.findIndex((i) => i.id === item.id);

    if (existingItemIndex >= 0) {
      // Up the frequency (Max 5)
      const currentFrequency = frequentItems[existingItemIndex].frequency;
      frequentItems[existingItemIndex].frequency = Math.min(currentFrequency + 1, MAX_FREQUENCY);
      frequentItems[existingItemIndex].lastUsed = new Date().getTime();
    } else {
      // Only store a max of 5 items
      if (frequentItems.length >= MAX_FREQUENT_ITEMS) {
        frequentItems.pop();
      }

      frequentItems.push({ ...item, frequency: 1, lastUsed: new Date().getTime() });
    }

    // Sort by frequency and lastUsed
    frequentItems.sort((a, b) => {
      if (a.frequency > b.frequency) {
        return -1;
      }
      if (a.frequency < b.frequency) {
        return 1;
      }
      return b.lastUsed - a.lastUsed;
    });

    // Note we do not need to commit a mutation here as immediately after this we refresh the page to
    // update the search results.
    localStorage.setItem(key, JSON.stringify(frequentItems));
    return frequentItems;
  } catch {
    // The LS got in a bad state, let's wipe it
    localStorage.removeItem(key);
    return [];
  }
};

export const mergeById = (inflatedData, storedData) => {
  return inflatedData.map((data) => {
    const stored = storedData?.find((d) => d.id === data.id) || {};
    return { ...stored, ...data };
  });
};

export const isSidebarDirty = (currentQuery, urlQuery) => {
  return SIDEBAR_PARAMS.some((param) => {
    // userAddParam ensures we don't get a false dirty from null !== undefined
    const userAddedParam = !urlQuery[param] && currentQuery[param];
    const userChangedExistingParam = urlQuery[param] && urlQuery[param] !== currentQuery[param];

    if (Array.isArray(currentQuery[param]) || Array.isArray(urlQuery[param])) {
      return !isEqual(currentQuery[param], urlQuery[param]);
    }

    return userAddedParam || userChangedExistingParam;
  });
};

export const formatSearchResultCount = (count) => {
  if (!count) {
    return '0';
  }

  const countNumber = typeof count === 'string' ? parseInt(count.replace(/,/g, ''), 10) : count;
  return formatNumber(countNumber, NUMBER_FORMATING_OPTIONS);
};

export const getAggregationsUrl = () => {
  const currentUrl = new URL(window.location.href);
  currentUrl.pathname = joinPaths('/search', 'aggregations');
  return currentUrl.toString();
};

const sortLanguages = (state, entries) => {
  const queriedLanguages = state.query?.[LANGUAGE_FILTER_PARAM] || [];

  if (!Array.isArray(queriedLanguages) || !queriedLanguages.length) {
    return entries;
  }

  const queriedLanguagesSet = new Set(queriedLanguages);

  return orderBy(entries, [({ key }) => queriedLanguagesSet.has(key), 'count'], ['desc', 'desc']);
};

const getUniqueNamesOnly = (items) => {
  return items.filter(
    (item, index, array) => index === array.findIndex((obj) => obj.title === item.title),
  );
};

export const prepareSearchAggregations = (state, aggregationData) =>
  aggregationData.map((item) => {
    if (item?.name === LANGUAGE_FILTER_PARAM) {
      return {
        ...item,
        buckets: sortLanguages(state, item.buckets),
      };
    }

    if (item?.name === LABEL_AGREGATION_NAME) {
      return {
        ...item,
        buckets: getUniqueNamesOnly(item.buckets),
      };
    }

    return item;
  });

export const addCountOverLimit = (count = '') => {
  return count.includes('+') ? '+' : '';
};

/** @param { string } link */
export const injectRegexSearch = (link) => {
  const urlObject = new URL(link, getBaseURL());
  const queryObject = queryToObject(urlObject.search);
  if (loadDataFromLS(LS_REGEX_HANDLE) && (queryObject.project_id || queryObject.group_id)) {
    queryObject[REGEX_PARAM] = true;
  }
  if (isEmpty(queryObject)) {
    return urlObject.pathname;
  }
  return `${urlObject.pathname}?${objectToQuery(queryObject)}`;
};

export const scopeCrawler = (navigation, parentScope = null) => {
  for (const value of Object.values(navigation)) {
    if (value.active) {
      return parentScope || value.scope;
    }

    if (value.sub_items) {
      const subItemScope = scopeCrawler(value.sub_items, value.scope);
      if (subItemScope) {
        return subItemScope;
      }
    }
  }

  return null;
};

export const skipBlobESCount = (state, itemScope) =>
  !(
    (state.query?.group_id || state.query?.project_id) &&
    window.gon.features?.zoektMultimatchFrontend &&
    state.zoektAvailable &&
    itemScope === SCOPE_BLOB
  );

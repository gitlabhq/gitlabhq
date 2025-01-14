import { intersection, difference } from 'lodash';
import {
  formatSearchResultCount,
  addCountOverLimit,
  injectRegexSearch,
  scopeCrawler,
} from '~/search/store/utils';

import {
  SCOPE_BLOB,
  LABEL_FILTER_PARAM,
  LABEL_AGREGATION_NAME,
  LANGUAGE_FILTER_PARAM,
} from '~/search/sidebar/constants';

import {
  GROUPS_LOCAL_STORAGE_KEY,
  PROJECTS_LOCAL_STORAGE_KEY,
  ICON_MAP,
  SUBITEMS_FILTER,
} from './constants';

const queryLabelFilters = (state) => state?.query?.[LABEL_FILTER_PARAM] || [];
const urlQueryLabelFilters = (state) => state?.urlQuery?.[LABEL_FILTER_PARAM] || [];

const appliedSelectedLabelsKeys = (state) =>
  intersection(urlQueryLabelFilters(state), queryLabelFilters(state));

const unselectedLabelsKeys = (state) =>
  difference(urlQueryLabelFilters(state), queryLabelFilters(state));

const unappliedNewLabelKeys = (state) => {
  return state?.query?.[LABEL_FILTER_PARAM]?.filter(
    (label) => !urlQueryLabelFilters(state)?.includes(label),
  );
};

export const queryLanguageFilters = (state) => state.query[LANGUAGE_FILTER_PARAM] || [];

export const frequentGroups = (state) => {
  return state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
};

export const frequentProjects = (state) => {
  return state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
};

export const languageAggregationBuckets = (state) => {
  return (
    state.aggregations.data.find((aggregation) => aggregation.name === LANGUAGE_FILTER_PARAM)
      ?.buckets || []
  );
};

export const labelAggregationBuckets = (state) => {
  return (
    state?.aggregations?.data?.find((aggregation) => aggregation.name === LABEL_AGREGATION_NAME)
      ?.buckets || []
  );
};

export const filteredLabels = (state) => {
  if (state.searchLabelString === '') {
    return labelAggregationBuckets(state);
  }
  return labelAggregationBuckets(state).filter((label) => {
    return label.title.toLowerCase().includes(state.searchLabelString.toLowerCase());
  });
};

export const filteredAppliedSelectedLabels = (state) =>
  filteredLabels(state)?.filter((label) => urlQueryLabelFilters(state)?.includes(label.title));

export const appliedSelectedLabels = (state) =>
  labelAggregationBuckets(state)?.filter((label) =>
    appliedSelectedLabelsKeys(state)?.includes(label.title),
  );

export const filteredUnselectedLabels = (state) =>
  filteredLabels(state)?.filter((label) => !urlQueryLabelFilters(state)?.includes(label.title));

export const unselectedLabels = (state) =>
  labelAggregationBuckets(state).filter((label) =>
    unselectedLabelsKeys(state)?.includes(label.title),
  );

export const unappliedNewLabels = (state) =>
  labelAggregationBuckets(state).filter((label) => {
    return unappliedNewLabelKeys(state)?.includes(label.title);
  });

export const currentScope = (state) => {
  return scopeCrawler(state.navigation);
};

export const navigationItems = (state) =>
  Object.values(state.navigation).map((item, index) => {
    const navigation = {
      id: `menu-${item.scope}-${index}`,
      scope: item.scope,
      title: item.label,
      icon: ICON_MAP[item.scope] || '',
      link: item.scope === SCOPE_BLOB ? injectRegexSearch(item.link) : item.link,
      is_active: Boolean(item?.active),
      pill_count: `${formatSearchResultCount(item?.count)}${addCountOverLimit(item?.count)}` || '',
    };

    if (item?.sub_items) {
      navigation.items = Object.keys(item.sub_items)
        .filter((subItem) => Boolean(SUBITEMS_FILTER[subItem]))
        .sort((a, b) => SUBITEMS_FILTER[a].order - SUBITEMS_FILTER[b].order)
        .map((subItem, subIndex) => {
          return {
            id: `menu-${subItem}-${subIndex}`,
            title: SUBITEMS_FILTER[subItem].label,
            link: item.sub_items[subItem].link,
            is_active: Boolean(item.sub_items[subItem]?.active),
          };
        });
    }

    return navigation;
  });

export const hasMissingProjectContext = (state) => !state?.projectInitialJson?.id;

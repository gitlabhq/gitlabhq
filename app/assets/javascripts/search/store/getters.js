import { findKey, intersection } from 'lodash';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';
import {
  LABEL_FILTER_PARAM,
  LABEL_AGREGATION_NAME,
} from '~/search/sidebar/components/label_filter/data';
import {
  formatSearchResultCount,
  addCountOverLimit,
  injectRegexSearch,
} from '~/search/store/utils';

import { SCOPE_BLOB } from '~/search/sidebar/constants';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY, ICON_MAP } from './constants';

const queryLabelFilters = (state) => state?.query?.[LABEL_FILTER_PARAM] || [];
const urlQueryLabelFilters = (state) => state?.urlQuery?.[LABEL_FILTER_PARAM] || [];

const appliedSelectedLabelsKeys = (state) =>
  intersection(urlQueryLabelFilters(state), queryLabelFilters(state));

const unselectedLabelsKeys = (state) =>
  urlQueryLabelFilters(state)?.filter((label) => !queryLabelFilters(state)?.includes(label));

const unappliedNewLabelKeys = (state) => {
  return state?.query?.[LABEL_FILTER_PARAM]?.filter(
    (label) => !urlQueryLabelFilters(state)?.includes(label),
  );
};

export const queryLanguageFilters = (state) => state.query[languageFilterData.filterParam] || [];

export const frequentGroups = (state) => {
  return state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
};

export const frequentProjects = (state) => {
  return state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
};

export const languageAggregationBuckets = (state) => {
  return (
    state.aggregations.data.find(
      (aggregation) => aggregation.name === languageFilterData.filterParam,
    )?.buckets || []
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

export const appliedSelectedLabels = (state) => {
  return labelAggregationBuckets(state)?.filter((label) =>
    appliedSelectedLabelsKeys(state)?.includes(label.title),
  );
};

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

export const currentScope = (state) => findKey(state.navigation, { active: true });

export const navigationItems = (state) =>
  Object.values(state.navigation).map((item) => ({
    title: item.label,
    icon: ICON_MAP[item.scope] || '',
    link: item.scope === SCOPE_BLOB ? injectRegexSearch(item.link) : item.link,
    is_active: Boolean(item?.active),
    pill_count: `${formatSearchResultCount(item?.count)}${addCountOverLimit(item?.count)}` || '',
    items: [],
  }));

export const hasMissingProjectContext = (state) => !state?.projectInitialJson?.id;

import { findKey, intersection } from 'lodash';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';
import { labelFilterData } from '~/search/sidebar/components/label_filter/data';
import {
  formatSearchResultCount,
  addCountOverLimit,
  injectRegexSearch,
} from '~/search/store/utils';

import { PROJECT_DATA, SCOPE_BLOB } from '~/search/sidebar/constants';
import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY, ICON_MAP } from './constants';

const queryLabelFilters = (state) => state?.query?.[labelFilterData.filterParam] || [];
const urlQueryLabelFilters = (state) => state?.urlQuery?.[labelFilterData.filterParam] || [];

const appliedSelectedLabelsKeys = (state) =>
  intersection(urlQueryLabelFilters(state), queryLabelFilters(state));

const unselectedLabelsKeys = (state) =>
  urlQueryLabelFilters(state)?.filter((label) => !queryLabelFilters(state)?.includes(label));

const unappliedNewLabelKeys = (state) =>
  state?.query?.labels?.filter((label) => !urlQueryLabelFilters(state)?.includes(label));

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
    state?.aggregations?.data?.find(
      (aggregation) => aggregation.name === labelFilterData.filterParam,
    )?.buckets || []
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
  filteredLabels(state)?.filter((label) => urlQueryLabelFilters(state)?.includes(label.key));

export const appliedSelectedLabels = (state) => {
  return labelAggregationBuckets(state)?.filter((label) =>
    appliedSelectedLabelsKeys(state)?.includes(label.key),
  );
};

export const filteredUnselectedLabels = (state) =>
  filteredLabels(state)?.filter((label) => !urlQueryLabelFilters(state)?.includes(label.key));

export const unselectedLabels = (state) =>
  labelAggregationBuckets(state).filter((label) =>
    unselectedLabelsKeys(state)?.includes(label.key),
  );

export const unappliedNewLabels = (state) =>
  labelAggregationBuckets(state).filter((label) =>
    unappliedNewLabelKeys(state)?.includes(label.key),
  );

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

export const showArchived = (state) => !state.query?.[PROJECT_DATA.queryParam];

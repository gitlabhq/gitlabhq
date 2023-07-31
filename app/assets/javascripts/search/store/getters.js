import { findKey } from 'lodash';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';
import { labelFilterData } from '~/search/sidebar/components/label_filter/data';
import { formatSearchResultCount, addCountOverLimit } from '~/search/store/utils';

import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY, ICON_MAP } from './constants';

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
  filteredLabels(state)?.filter((label) => state?.urlQuery?.labels?.includes(label.key));

export const appliedSelectedLabels = (state) => {
  return labelAggregationBuckets(state)?.filter((label) =>
    state?.urlQuery?.labels?.includes(label.key),
  );
};

export const filteredUnselectedLabels = (state) => {
  if (!state?.urlQuery?.labels) {
    return filteredLabels(state);
  }

  return filteredLabels(state)?.filter((label) => !state?.urlQuery?.labels?.includes(label.key));
};

export const currentScope = (state) => findKey(state.navigation, { active: true });

export const queryLanguageFilters = (state) => state.query[languageFilterData.filterParam] || [];

export const navigationItems = (state) =>
  Object.values(state.navigation).map((item) => ({
    title: item.label,
    icon: ICON_MAP[item.scope] || '',
    link: item.link,
    is_active: Boolean(item?.active),
    pill_count: `${formatSearchResultCount(item?.count)}${addCountOverLimit(item?.count)}` || '',
    items: [],
  }));

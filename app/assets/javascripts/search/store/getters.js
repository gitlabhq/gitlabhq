import { findKey, has } from 'lodash';
import { languageFilterData } from '~/search/sidebar/components/language_filter/data';
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

export const currentScope = (state) => findKey(state.navigation, { active: true });

export const queryLanguageFilters = (state) => state.query[languageFilterData.filterParam] || [];

export const currentUrlQueryHasLanguageFilters = (state) =>
  has(state.urlQuery, languageFilterData.filterParam) &&
  state.urlQuery[languageFilterData.filterParam]?.length > 0;

export const navigationItems = (state) =>
  Object.values(state.navigation).map((item) => ({
    title: item.label,
    icon: ICON_MAP[item.scope] || '',
    link: item.link,
    is_active: Boolean(item?.active),
    pill_count: `${formatSearchResultCount(item?.count)}${addCountOverLimit(item?.count)}` || '',
    items: [],
  }));

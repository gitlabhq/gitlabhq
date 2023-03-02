import { findKey, has } from 'lodash';
import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';

import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from './constants';

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

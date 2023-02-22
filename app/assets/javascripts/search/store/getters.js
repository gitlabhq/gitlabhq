import { has } from 'lodash';
import { languageFilterData } from '~/search/sidebar/constants/language_filter_data';

import { GROUPS_LOCAL_STORAGE_KEY, PROJECTS_LOCAL_STORAGE_KEY } from './constants';

export const frequentGroups = (state) => {
  return state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
};

export const frequentProjects = (state) => {
  return state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
};

export const langugageAggregationBuckets = (state) => {
  return (
    state.aggregations.data.find(
      (aggregation) => aggregation.name === languageFilterData.filterParam,
    )?.buckets || []
  );
};

export const queryLangugageFilters = (state) => {
  return state.query[languageFilterData.filterParam] || [];
};

export const currentUrlQueryHasLanguageFilters = (state) =>
  has(state.urlQuery, languageFilterData.filterParam) &&
  state.urlQuery[languageFilterData.filterParam]?.length > 0;

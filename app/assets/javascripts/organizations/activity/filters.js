import { processFilters } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

export const CONTRIBUTION_TYPE_FILTER_TYPE = 'contribution_type';

export const RECENT_SEARCHES_STORAGE_KEY = 'recent-organizations-activity-filter-search';
export const FILTERED_SEARCH_NAMESPACE = 'organizations-activity-filter-search';

export const convertTokensToFilter = (tokens) => {
  const processedFilters = processFilters(tokens);

  if (!processedFilters[CONTRIBUTION_TYPE_FILTER_TYPE]) {
    return null;
  }

  return processedFilters[CONTRIBUTION_TYPE_FILTER_TYPE][0]?.value;
};

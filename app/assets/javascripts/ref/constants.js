import { __ } from '~/locale';

export const X_TOTAL_HEADER = 'x-total';

export const SEARCH_DEBOUNCE_MS = 250;

export const DEFAULT_I18N = Object.freeze({
  dropdownHeader: __('Select Git revision'),
  searchPlaceholder: __('Search by Git revision'),
  noResultsWithQuery: __('No matching results for "%{query}"'),
  noResults: __('No matching results'),
  branchesErrorMessage: __('An error occurred while fetching branches.  Retry the search.'),
  tagsErrorMessage: __('An error occurred while fetching tags. Retry the search.'),
  commitsErrorMessage: __('An error occurred while fetching commits.  Retry the search.'),
  branches: __('Branches'),
  tags: __('Tags'),
  commits: __('Commits'),
  noRefSelected: __('No ref selected'),
});

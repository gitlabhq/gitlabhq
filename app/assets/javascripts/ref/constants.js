import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';

export const REF_TYPE_BRANCHES = 'REF_TYPE_BRANCHES';
export const REF_TYPE_TAGS = 'REF_TYPE_TAGS';
export const REF_TYPE_COMMITS = 'REF_TYPE_COMMITS';
export const ALL_REF_TYPES = Object.freeze([REF_TYPE_BRANCHES, REF_TYPE_TAGS, REF_TYPE_COMMITS]);

export const X_TOTAL_HEADER = 'x-total';

export const SEARCH_DEBOUNCE_MS = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

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

import { s__, __ } from '~/locale';

export const AUTOCOMPLETE_ERROR_MESSAGE = s__(
  'GlobalSearch|There was an error fetching search autocomplete suggestions.',
);

export const ALL_GITLAB = __('All GitLab');
export const PLACES = s__('GlobalSearch|Places');

export const COMMAND_PALETTE = s__('GlobalSearch|Command palette');
export const SEARCH_DESCRIBED_BY_DEFAULT = s__(
  'GlobalSearch|%{count} default results provided. Use the up and down arrow keys to navigate search results list.',
);
export const SEARCH_DESCRIBED_BY_WITH_RESULTS = s__(
  'GlobalSearch|Type for new suggestions to appear below.',
);
export const SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN = s__(
  'GlobalSearch|Type and press the enter key to submit search.',
);
export const SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN = SEARCH_DESCRIBED_BY_WITH_RESULTS;
export const SEARCH_DESCRIBED_BY_UPDATED = s__(
  'GlobalSearch|Results updated. %{count} results available. Use the up and down arrow keys to navigate search results list, or ENTER to submit.',
);
export const SEARCH_RESULTS_LOADING = s__('GlobalSearch|Search results are loading');
export const SEARCH_RESULTS_SCOPE = s__('GlobalSearch|in %{scope}');
export const MIN_SEARCH_TERM = s__(
  'GlobalSearch|The search term must be at least 3 characters long.',
);
export const MSG_ISSUES_ASSIGNED_TO_ME = s__('GlobalSearch|Issues assigned to me');

export const MSG_ISSUES_IVE_CREATED = s__("GlobalSearch|Issues I've created");

export const MSG_MR_ASSIGNED_TO_ME = s__('GlobalSearch|Merge requests assigned to me');

export const MSG_MR_IM_REVIEWER = s__("GlobalSearch|Merge requests that I'm a reviewer");

export const MSG_MR_IVE_CREATED = s__("GlobalSearch|Merge requests I've created");

export const MSG_IN_ALL_GITLAB = s__('GlobalSearch|all GitLab');

export const GROUPS_CATEGORY = s__('GlobalSearch|Groups');

export const PROJECTS_CATEGORY = s__('GlobalSearch|Projects');

export const USERS_CATEGORY = s__('GlobalSearch|Users');

export const ISSUES_CATEGORY = s__('GlobalSearch|Recent issues');

export const MERGE_REQUEST_CATEGORY = s__('GlobalSearch|Recent merge requests');

export const RECENT_EPICS_CATEGORY = s__('GlobalSearch|Recent epics');

export const IN_THIS_PROJECT_CATEGORY = s__('GlobalSearch|In this project');

export const SETTINGS_CATEGORY = s__('GlobalSearch|Settings');

export const HELP_CATEGORY = s__('GlobalSearch|Help');

export const SEARCH_RESULTS_ORDER = [
  MERGE_REQUEST_CATEGORY,
  ISSUES_CATEGORY,
  RECENT_EPICS_CATEGORY,
  GROUPS_CATEGORY,
  PROJECTS_CATEGORY,
  USERS_CATEGORY,
  IN_THIS_PROJECT_CATEGORY,
  SETTINGS_CATEGORY,
  HELP_CATEGORY,
];
export const SEARCH_LABELS = s__('GlobalSearch|Search labels');

export const DROPDOWN_HEADER = s__('GlobalSearch|Labels');

export const AGGREGATIONS_ERROR_MESSAGE = s__('GlobalSearch|Fetching aggregations error.');

export const NO_LABELS_FOUND = s__('GlobalSearch|No labels found');

export const I18N = {
  SEARCH_DESCRIBED_BY_DEFAULT,
  SEARCH_RESULTS_LOADING,
  SEARCH_DESCRIBED_BY_UPDATED,
  SEARCH_INPUT_DESCRIBE_BY_WITH_DROPDOWN,
  SEARCH_INPUT_DESCRIBE_BY_NO_DROPDOWN,
  SEARCH_LABELS,
  DROPDOWN_HEADER,
  AGGREGATIONS_ERROR_MESSAGE,
  NO_LABELS_FOUND,
};

import { s__, __ } from '~/locale';

export const AUTOCOMPLETE_ERROR_MESSAGE = s__(
  'GlobalSearch|There was an error fetching search autocomplete suggestions.',
);

export const NO_SEARCH_RESULTS = s__(
  'GlobalSearch|No results found. Edit your search and try again.',
);

export const ALL_GITLAB = __('All GitLab');
export const PLACES = s__('GlobalSearch|Places');

export const COMMAND_PALETTE = s__('GlobalSearch|Command palette');
export const DESCRIBE_LABEL_FILTER = s__('GlobalSearch|List of filtered labels.');
export const DESCRIBE_LABEL_FILTER_INPUT = s__('GlobalSearch|Type to filter labels.');
export const SEARCH_DESCRIBED_BY_DEFAULT = s__(
  'GlobalSearch|%{count} default results provided. Use the up and down arrow keys to navigate search results list.',
);
export const SEARCH_DESCRIBED_BY_WITH_RESULTS = s__(
  'GlobalSearch|Type for new suggestions to appear below.',
);
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

export const MSG_MR_IM_WORKING_ON = s__("GlobalSearch|Merge requests I'm working on");

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

export const COMMAND_PALETTE_TIP = s__('GlobalSearch|Tip:');

export const COMMAND_PALETTE_TYPE_PAGES = s__('GlobalSearch|Pages or actions');

export const COMMAND_PALETTE_TYPE_FILES = s__('GlobalSearch|Files');

export const COMMAND_PALETTE_SEARCH_SCOPE_HEADER = s__(
  'GlobalSearch|Search for `%{searchTerm}` in...',
);

export const COMMAND_PALETTE_PAGES_SCOPE_HEADER = s__(
  'GlobalSearch|Search for `%{searchTerm}` pages in...',
);

export const COMMAND_PALETTE_USERS_SCOPE_HEADER = s__(
  'GlobalSearch|Search for `%{searchTerm}` users in...',
);

export const COMMAND_PALETTE_PROJECTS_SCOPE_HEADER = s__(
  'GlobalSearch|Search for `%{searchTerm}` projects in...',
);

export const COMMAND_PALETTE_FILES_SCOPE_HEADER = s__(
  'GlobalSearch|Search for `%{searchTerm}` files in...',
);

export const COMMAND_PALETTE_PAGES_CHAR = '>';
export const COMMAND_PALETTE_USERS_CHAR = '@';
export const COMMAND_PALETTE_PROJECTS_CHAR = ':';
export const COMMAND_PALETTE_FILES_CHAR = '~';

export const I18N = {
  SEARCH_DESCRIBED_BY_DEFAULT,
  SEARCH_RESULTS_LOADING,
  SEARCH_DESCRIBED_BY_UPDATED,
  SEARCH_LABELS,
  DROPDOWN_HEADER,
  AGGREGATIONS_ERROR_MESSAGE,
  NO_LABELS_FOUND,
  DESCRIBE_LABEL_FILTER,
  DESCRIBE_LABEL_FILTER_INPUT,
};

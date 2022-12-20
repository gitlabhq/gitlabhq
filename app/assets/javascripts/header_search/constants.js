import { s__ } from '~/locale';

export const MSG_ISSUES_ASSIGNED_TO_ME = s__('GlobalSearch|Issues assigned to me');

export const MSG_ISSUES_IVE_CREATED = s__("GlobalSearch|Issues I've created");

export const MSG_MR_ASSIGNED_TO_ME = s__('GlobalSearch|Merge requests assigned to me');

export const MSG_MR_IM_REVIEWER = s__("GlobalSearch|Merge requests that I'm a reviewer");

export const MSG_MR_IVE_CREATED = s__("GlobalSearch|Merge requests I've created");

export const MSG_IN_ALL_GITLAB = s__('GlobalSearch|all GitLab');

export const MSG_IN_GROUP = s__('GlobalSearch|group');

export const MSG_IN_PROJECT = s__('GlobalSearch|project');

export const ICON_PROJECT = 'project';

export const ICON_GROUP = 'group';

export const ICON_SUBGROUP = 'subgroup';

export const GROUPS_CATEGORY = s__('GlobalSearch|Groups');

export const PROJECTS_CATEGORY = s__('GlobalSearch|Projects');

export const USERS_CATEGORY = s__('GlobalSearch|Users');

export const ISSUES_CATEGORY = s__('GlobalSearch|Recent issues');

export const MERGE_REQUEST_CATEGORY = s__('GlobalSearch|Recent merge requests');

export const RECENT_EPICS_CATEGORY = s__('GlobalSearch|Recent epics');

export const IN_THIS_PROJECT_CATEGORY = s__('GlobalSearch|In this project');

export const SETTINGS_CATEGORY = s__('GlobalSearch|Settings');

export const HELP_CATEGORY = s__('GlobalSearch|Help');

export const LARGE_AVATAR_PX = 32;

export const SMALL_AVATAR_PX = 16;

export const FIRST_DROPDOWN_INDEX = 0;

export const SEARCH_BOX_INDEX = -1;

export const SEARCH_SHORTCUTS_MIN_CHARACTERS = 2;

export const SEARCH_INPUT_DESCRIPTION = 'search-input-description';

export const SEARCH_RESULTS_DESCRIPTION = 'search-results-description';

export const SCOPE_TOKEN_MAX_LENGTH = 36;

export const INPUT_FIELD_PADDING = 52;

export const HEADER_INIT_EVENTS = ['input', 'focus'];

export const IS_SEARCHING = 'is-searching';
export const IS_FOCUSED = 'is-focused';
export const IS_NOT_FOCUSED = 'is-not-focused';

export const DROPDOWN_ORDER = [
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

export const FETCH_TYPES = ['generic', 'search'];

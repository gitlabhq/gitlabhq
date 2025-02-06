import { s__ } from '~/locale';

export const COMMAND_HANDLE = '>';
export const USER_HANDLE = '@';
export const PROJECT_HANDLE = ':';
export const ISSUE_HANDLE = '#';
export const PATH_HANDLE = '~';

export const COMMANDS_TOGGLE_KEYBINDING = 'mod+k';
export const COMMANDS_SKIP_NEXT_KEYBINDING = ['ctrl+n', 'command+n', 'alt+mod+n'];
export const COMMANDS_SKIP_PREV_KEYBINDING = ['ctrl+p', 'command+p', 'alt+mod+p'];

export const TRACKING_ACTIVATE_COMMAND_PALETTE = 'activate_command_palette';
export const TRACKING_CLICK_COMMAND_PALETTE_ITEM = 'click_command_palette_item';
export const TRACKING_HANDLE_LABEL_MAP = {
  [COMMAND_HANDLE]: 'command',
  [USER_HANDLE]: 'user',
  [PROJECT_HANDLE]: 'project',
  [PATH_HANDLE]: 'path',
  // No ISSUE_HANDLE. See https://gitlab.com/gitlab-org/gitlab/-/issues/417434.
};

export const COMMON_HANDLES = [COMMAND_HANDLE, USER_HANDLE, PROJECT_HANDLE, PATH_HANDLE];

export const SEARCH_SCOPE_PLACEHOLDER = {
  [COMMAND_HANDLE]: s__('CommandPalette|command'),
  [USER_HANDLE]: s__('CommandPalette|user (enter at least 3 chars)'),
  [PROJECT_HANDLE]: s__('CommandPalette|project (enter at least 3 chars)'),
  [ISSUE_HANDLE]: s__('CommandPalette|issue (enter at least 3 chars)'),
  [PATH_HANDLE]: s__('CommandPalette|go to project file'),
};

export const SEARCH_SCOPE = {
  [USER_HANDLE]: 'users',
  [PROJECT_HANDLE]: 'projects',
  [ISSUE_HANDLE]: 'issues',
};

export const GLOBAL_COMMANDS_GROUP_TITLE = s__('CommandPalette|Global Commands');
export const USERS_GROUP_TITLE = s__('GlobalSearch|Users');
export const PAGES_GROUP_TITLE = s__('CommandPalette|Pages');
export const PROJECTS_GROUP_TITLE = s__('GlobalSearch|Projects');
export const GROUPS_GROUP_TITLE = s__('GlobalSearch|Groups');
export const ISSUES_GROUP_TITLE = s__('GlobalSearch|Issues');
export const PATH_GROUP_TITLE = s__('CommandPalette|Project files');
export const SETTINGS_GROUP_TITLE = s__('CommandPalette|Settings');

export const MODAL_CLOSE_ESC = 'esc';
export const MODAL_CLOSE_BACKGROUND = 'backdrop';
export const MODAL_CLOSE_HEADERCLOSE = 'headerclose';

export const SCOPE_SEARCH_ALL = 'scoped-in-all';
export const SCOPE_SEARCH_GROUP = 'scoped-in-group';
export const SCOPE_SEARCH_PROJECT = 'scoped-in-project';

export const GROUP_TITLES = {
  [USER_HANDLE]: USERS_GROUP_TITLE,
  [PROJECT_HANDLE]: PROJECTS_GROUP_TITLE,
  [ISSUE_HANDLE]: ISSUES_GROUP_TITLE,
  [PATH_HANDLE]: PATH_GROUP_TITLE,
};

export const MAX_ROWS = 20;

export const OVERLAY_CHANGE_CONTEXT = s__('GlobalSearch|Change context %{kbdStart}↵%{kbdEnd}');
export const OVERLAY_SEARCH = s__('GlobalSearch|Search %{kbdStart}↵%{kbdEnd}');

export const OVERLAY_PROFILE = s__('GlobalSearch|Go to profile %{kbdStart}↵%{kbdEnd}');

export const OVERLAY_PROJECT = s__('GlobalSearch|Go to project %{kbdStart}↵%{kbdEnd}');

export const OVERLAY_FILE = s__('GlobalSearch|Go to file %{kbdStart}↵%{kbdEnd}');

export const OVERLAY_GOTO = s__('GlobalSearch|Go to %{kbdStart}↵%{kbdEnd}');

export const FREQUENTLY_VISITED_PROJECTS_HANDLE = 'FREQUENTLY_VISITED_PROJECTS_HANDLE';
export const FREQUENTLY_VISITED_GROUPS_HANDLE = 'FREQUENTLY_VISITED_GROUPS_HANDLE';

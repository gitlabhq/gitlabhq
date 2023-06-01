import { s__, sprintf } from '~/locale';

export const USERS_ENDPOINT = '/-/autocomplete/users.json';
export const COMMAND_HANDLE = '>';
export const USER_HANDLE = '@';

export const COMMON_HANDLES = [COMMAND_HANDLE, USER_HANDLE];
export const SEARCH_OR_COMMAND_MODE_PLACEHOLDER = sprintf(
  s__(
    'CommandPalette|Type %{commandHandle} for command, %{userHandle} for user or perform generic search...',
  ),
  {
    commandHandle: COMMAND_HANDLE,
    userHandle: USER_HANDLE,
  },
  false,
);

export const SEARCH_SCOPE = {
  [COMMAND_HANDLE]: s__('CommandPalette|command'),
  [USER_HANDLE]: s__('CommandPalette|user (enter at least 3 chars)'),
};

export const COMMANDS_GROUP_TITLE = s__('CommandPalette|Commands');
export const USERS_GROUP_TITLE = s__('CommandPalette|Users');

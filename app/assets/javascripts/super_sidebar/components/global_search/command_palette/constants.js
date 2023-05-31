import { s__, sprintf } from '~/locale';

export const COMMAND_HANDLE = '>';

export const COMMON_HANDLES = [COMMAND_HANDLE];
export const SEARCH_OR_COMMAND_MODE_PLACEHOLDER = sprintf(
  s__('CommandPalette|Type %{commandHandle} for command or search...'),
  {
    commandHandle: COMMAND_HANDLE,
  },
  false,
);

export const SEARCH_SCOPE = {
  [COMMAND_HANDLE]: s__('CommandPalette|command'),
};

export const COMMANDS_GROUP_TITLE = s__('CommandPalette|Commands');

import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';
import { OptionsMenuAdapter } from '~/rapid_diffs/options_menu/adapter';
import { ToggleFileAdapter } from '~/rapid_diffs/toggle_file/adapter';

const HEADER_ADAPTERS = [OptionsMenuAdapter, ToggleFileAdapter];

export const VIEWER_ADAPTERS = {
  text_inline: [...HEADER_ADAPTERS, ExpandLinesAdapter],
  text_parallel: [...HEADER_ADAPTERS, ExpandLinesAdapter],
  no_preview: HEADER_ADAPTERS,
};

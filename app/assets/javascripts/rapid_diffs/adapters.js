import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';
import { OptionsMenuAdapter } from '~/rapid_diffs/options_menu/adapter';
import { ToggleFileAdapter } from '~/rapid_diffs/toggle_file/adapter';
import { DisableDiffSideAdapter } from '~/rapid_diffs/disable_diff_side/adapter';
import { ImageAdapter } from '~/rapid_diffs/image_viewer/adapter';
import { LoadFileAdapter } from '~/rapid_diffs/load_file/adapter';

const HEADER_ADAPTERS = [OptionsMenuAdapter, ToggleFileAdapter];

export const VIEWER_ADAPTERS = {
  text_inline: [...HEADER_ADAPTERS, ExpandLinesAdapter],
  text_parallel: [...HEADER_ADAPTERS, ExpandLinesAdapter, DisableDiffSideAdapter],
  image: [...HEADER_ADAPTERS, ImageAdapter],
  no_preview: [...HEADER_ADAPTERS, LoadFileAdapter],
};

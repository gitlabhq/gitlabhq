import { expandLinesAdapter } from '~/rapid_diffs/adapters/expand_lines';
import { optionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';
import { toggleFileAdapter } from '~/rapid_diffs/adapters/toggle_file';
import { disableDiffSideAdapter } from '~/rapid_diffs/adapters/disable_diff_side';
import { imageAdapter } from '~/rapid_diffs/adapters/image_viewer';
import { loadFileAdapter } from '~/rapid_diffs/adapters/load_file';
import { lineLinkAdapter } from '~/rapid_diffs/adapters/line_link';

const HEADER_ADAPTERS = [optionsMenuAdapter, toggleFileAdapter];

export const VIEWER_ADAPTERS = {
  text_inline: [...HEADER_ADAPTERS, expandLinesAdapter, lineLinkAdapter],
  text_parallel: [...HEADER_ADAPTERS, expandLinesAdapter, disableDiffSideAdapter, lineLinkAdapter],
  image: [...HEADER_ADAPTERS, imageAdapter],
  no_preview: [...HEADER_ADAPTERS, loadFileAdapter],
};

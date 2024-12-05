import { ExpandLinesAdapter } from '~/rapid_diffs/expand_lines/adapter';

const RAPID_DIFFS_VIEWERS = {
  text_inline: 'text_inline',
  text_parallel: 'text_parallel',
};

export const VIEWER_ADAPTERS = {
  [RAPID_DIFFS_VIEWERS.text_inline]: [ExpandLinesAdapter],
  [RAPID_DIFFS_VIEWERS.text_parallel]: [ExpandLinesAdapter],
};

import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import {
  inlineDiscussionsAdapter,
  parallelDiscussionsAdapter,
} from '~/rapid_diffs/adapters/discussions';
import { optionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';
import { commitDiffsOptionsMenuAdapter } from '~/rapid_diffs/adapters/commit_diffs_options_menu';

export const adapters = {
  text_inline: [
    ...VIEWER_ADAPTERS.text_inline.filter((a) => a !== optionsMenuAdapter),
    commitDiffsOptionsMenuAdapter,
    inlineDiscussionsAdapter,
  ],
  text_parallel: [
    ...VIEWER_ADAPTERS.text_parallel.filter((a) => a !== optionsMenuAdapter),
    commitDiffsOptionsMenuAdapter,
    parallelDiscussionsAdapter,
  ],
};

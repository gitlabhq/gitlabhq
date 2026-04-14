import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import {
  commitInlineDiscussionsAdapter,
  commitParallelDiscussionsAdapter,
  commitNoPreviewDiscussionsAdapter,
} from '~/rapid_diffs/adapters/commit_discussions';
import { lineHighlightingAdapter } from '~/rapid_diffs/adapters/line_highlighting';
import { optionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';
import { commitDiffsOptionsMenuAdapter } from '~/rapid_diffs/adapters/commit_diffs_options_menu';
import { commitImageViewerAdapter } from '~/rapid_diffs/adapters/commit_image_viewer';
import { imageAdapter } from '~/rapid_diffs/adapters/image_viewer';

export const adapters = {
  ...VIEWER_ADAPTERS,
  no_preview: [...VIEWER_ADAPTERS.no_preview, commitNoPreviewDiscussionsAdapter],
  image: [...VIEWER_ADAPTERS.image.filter((a) => a !== imageAdapter), commitImageViewerAdapter],
  text_inline: [
    ...VIEWER_ADAPTERS.text_inline.filter((a) => a !== optionsMenuAdapter),
    commitDiffsOptionsMenuAdapter,
    commitInlineDiscussionsAdapter,
    lineHighlightingAdapter,
  ],
  text_parallel: [
    ...VIEWER_ADAPTERS.text_parallel.filter((a) => a !== optionsMenuAdapter),
    commitDiffsOptionsMenuAdapter,
    commitParallelDiscussionsAdapter,
    lineHighlightingAdapter,
  ],
};

import { HEADER_ADAPTERS, VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import { createLineDiscussionsAdapter } from '~/rapid_diffs/adapters/line_discussions';
import { createFileDiscussionsAdapter } from '~/rapid_diffs/adapters/file_discussions';
import { createNoPreviewDiscussionsAdapter } from '~/rapid_diffs/adapters/no_preview_discussions';
import { lineHighlightingAdapter } from '~/rapid_diffs/adapters/line_highlighting';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { viewedAdapter } from '~/rapid_diffs/adapters/viewed';
import { pinia } from '~/pinia/instance';
import { s__ } from '~/locale';

const MR_HEADER_ADAPTERS = [...HEADER_ADAPTERS, viewedAdapter];

const store = useMergeRequestDiscussions(pinia);
const discussionsErrorMessage = s__(
  'RapidDiffs|Some discussions for this file could not be displayed. View them in the Overview tab.',
);
const inlineDiscussionsAdapter = createLineDiscussionsAdapter({
  store,
  parallel: false,
  errorMessage: discussionsErrorMessage,
});
const parallelDiscussionsAdapter = createLineDiscussionsAdapter({
  store,
  parallel: true,
  errorMessage: discussionsErrorMessage,
});
const fileDiscussionsAdapter = createFileDiscussionsAdapter(store);
const noPreviewDiscussionsAdapter = createNoPreviewDiscussionsAdapter(store);

export const adapters = {
  text_inline: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_inline.slice(HEADER_ADAPTERS.length),
    inlineDiscussionsAdapter,
    lineHighlightingAdapter,
    fileDiscussionsAdapter,
  ],
  text_parallel: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_parallel.slice(HEADER_ADAPTERS.length),
    parallelDiscussionsAdapter,
    lineHighlightingAdapter,
    fileDiscussionsAdapter,
  ],
  image: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.image.slice(HEADER_ADAPTERS.length),
    fileDiscussionsAdapter,
  ],
  no_preview: [...MR_HEADER_ADAPTERS, fileDiscussionsAdapter, noPreviewDiscussionsAdapter],
};

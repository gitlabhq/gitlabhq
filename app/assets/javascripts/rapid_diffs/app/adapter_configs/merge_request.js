import { HEADER_ADAPTERS, VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import {
  createInlineDiscussionsAdapter,
  createParallelDiscussionsAdapter,
} from '~/rapid_diffs/adapters/discussions';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { viewedAdapter } from '~/rapid_diffs/adapters/viewed';
import { pinia } from '~/pinia/instance';

const MR_HEADER_ADAPTERS = [...HEADER_ADAPTERS, viewedAdapter];

const mergeRequestStore = useMergeRequestDiscussions(pinia);
const inlineDiscussionsAdapter = createInlineDiscussionsAdapter(mergeRequestStore);
const parallelDiscussionsAdapter = createParallelDiscussionsAdapter(mergeRequestStore);

export const adapters = {
  text_inline: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_inline.slice(HEADER_ADAPTERS.length),
    inlineDiscussionsAdapter,
  ],
  text_parallel: [
    ...MR_HEADER_ADAPTERS,
    ...VIEWER_ADAPTERS.text_parallel.slice(HEADER_ADAPTERS.length),
    parallelDiscussionsAdapter,
  ],
  image: [...MR_HEADER_ADAPTERS, ...VIEWER_ADAPTERS.image.slice(HEADER_ADAPTERS.length)],
  no_preview: [...MR_HEADER_ADAPTERS],
};

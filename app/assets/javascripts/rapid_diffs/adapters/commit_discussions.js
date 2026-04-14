import { createLineDiscussionsAdapter } from '~/rapid_diffs/adapters/line_discussions';
import { createNoPreviewDiscussionsAdapter } from '~/rapid_diffs/adapters/no_preview_discussions';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';
import { s__ } from '~/locale';

const discussionsErrorMessage = s__(
  'RapidDiffs|Some discussions for this file could not be displayed.',
);

export const commitInlineDiscussionsAdapter = createLineDiscussionsAdapter({
  store: commitDiffDiscussionsStore,
  parallel: false,
  errorMessage: discussionsErrorMessage,
});
export const commitParallelDiscussionsAdapter = createLineDiscussionsAdapter({
  store: commitDiffDiscussionsStore,
  parallel: true,
  errorMessage: discussionsErrorMessage,
});
export const commitNoPreviewDiscussionsAdapter = createNoPreviewDiscussionsAdapter(
  commitDiffDiscussionsStore,
);

import { createLineDiscussionsAdapter } from '~/rapid_diffs/adapters/line_discussions';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';

export const commitInlineDiscussionsAdapter = createLineDiscussionsAdapter({
  store: commitDiffDiscussionsStore,
  parallel: false,
});
export const commitParallelDiscussionsAdapter = createLineDiscussionsAdapter({
  store: commitDiffDiscussionsStore,
  parallel: true,
});

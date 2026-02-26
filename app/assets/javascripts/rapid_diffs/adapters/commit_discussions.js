import {
  createInlineDiscussionsAdapter,
  createParallelDiscussionsAdapter,
} from '~/rapid_diffs/adapters/discussions';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';

export const commitInlineDiscussionsAdapter = createInlineDiscussionsAdapter(
  commitDiffDiscussionsStore,
);
export const commitParallelDiscussionsAdapter = createParallelDiscussionsAdapter(
  commitDiffDiscussionsStore,
);

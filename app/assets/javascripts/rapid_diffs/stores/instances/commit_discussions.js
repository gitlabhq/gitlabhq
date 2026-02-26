import { useCommitDiffDiscussions } from '~/rapid_diffs/stores/commit_discussions_store';
import { pinia } from '~/pinia/instance';

export const commitDiffDiscussionsStore = useCommitDiffDiscussions(pinia);

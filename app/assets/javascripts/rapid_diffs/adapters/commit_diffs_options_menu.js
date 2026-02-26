import CommitDiffsFileOptionsDropdown from '~/rapid_diffs/app/options_menu/commit_diffs_file_options_dropdown.vue';
import { createOptionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';

export const commitDiffsOptionsMenuAdapter = createOptionsMenuAdapter(
  CommitDiffsFileOptionsDropdown,
  commitDiffDiscussionsStore,
);

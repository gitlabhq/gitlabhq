import CommitDiffsFileOptionsDropdown from '~/rapid_diffs/app/options_menu/commit_diffs_file_options_dropdown.vue';
import { createOptionsMenuAdapter } from '~/rapid_diffs/adapters/options_menu';

export const commitDiffsOptionsMenuAdapter = createOptionsMenuAdapter(
  CommitDiffsFileOptionsDropdown,
);

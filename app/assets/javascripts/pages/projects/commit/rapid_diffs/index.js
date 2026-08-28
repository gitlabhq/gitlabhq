import ZenMode from '~/zen_mode';
import { fetchCommitMergeRequests } from '~/commit_merge_requests';
import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initCommitOptionsDropdown from '~/projects/commit/init_commit_options_dropdown';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import initCommitPipelineSummary from '~/projects/commit_box/info/init_commit_pipeline_summary';
import initCommitReferences from '~/projects/commit_box/info/init_commit_references';
import { createCommitRapidDiffsApp } from '~/rapid_diffs/commit_app';

// eslint-disable-next-line no-new
new ZenMode();
fetchCommitMergeRequests();
initCommitPipelineSummary();
initCommitReferences();

initRevertCommitModal();
initCherryPickCommitModal();
initCommitOptionsDropdown();

const app = createCommitRapidDiffsApp();
app.init();

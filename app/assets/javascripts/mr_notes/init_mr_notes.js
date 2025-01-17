import initCherryPickCommitModal from '~/projects/commit/init_cherry_pick_commit_modal';
import initRevertCommitModal from '~/projects/commit/init_revert_commit_modal';
import { initMrStateLazyLoad } from '~/mr_notes/init';
import MergeRequest from '../merge_request';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';

export default function initMrNotes() {
  resetServiceWorkersPublicPath();

  const mrShowNode = document.querySelector('.merge-request');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrShowNode.dataset.mrAction,
  });

  initMrStateLazyLoad();

  document.addEventListener('merged:UpdateActions', () => {
    initRevertCommitModal('i_code_review_post_merge_submit_revert_modal');
    initCherryPickCommitModal('i_code_review_post_merge_submit_cherry_pick_modal');
  });
}

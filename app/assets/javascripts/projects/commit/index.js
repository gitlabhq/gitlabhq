import initRevertCommitTrigger from './init_revert_commit_trigger';
import initRevertCommitModal from './init_revert_commit_modal';
import initCherryPickCommitTrigger from './init_cherry_pick_commit_trigger';
import initCherryPickCommitModal from './init_cherry_pick_commit_modal';

export default () => {
  initRevertCommitModal();
  initRevertCommitTrigger();
  initCherryPickCommitModal();
  initCherryPickCommitTrigger();
};

import initCherryPickCommitModal from './init_cherry_pick_commit_modal';
import initCommitCommentsButton from './init_commit_comments_button';
import initCommitOptionsDropdown from './init_commit_options_dropdown';
import initRevertCommitModal from './init_revert_commit_modal';

export default () => {
  initRevertCommitModal();
  initCherryPickCommitModal();
  initCommitCommentsButton();
  initCommitOptionsDropdown();
};

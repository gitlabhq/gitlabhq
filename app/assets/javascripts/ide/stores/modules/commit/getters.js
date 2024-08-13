import { __ } from '~/locale';
import { COMMIT_TO_NEW_BRANCH } from './constants';

const BRANCH_SUFFIX_COUNT = 5;
const createTranslatedTextForFiles = (files, text) => {
  if (!files.length) return null;

  const filesPart = files.reduce((acc, val) => acc.concat(val.path), []).join(', ');

  return `${text} ${filesPart}`;
};

export const discardDraftButtonDisabled = (state) =>
  state.commitMessage === '' || state.submitCommitLoading;

// Note: If changing the structure of the placeholder branch name, please also
// update #patch_branch_name in app/helpers/tree_helper.rb
export const placeholderBranchName = (state, _, rootState) =>
  `${gon.current_username}-${rootState.currentBranchId}-patch-${`${new Date().getTime()}`.substr(
    -BRANCH_SUFFIX_COUNT,
  )}`;

export const branchName = (state, getters, rootState) => {
  if (getters.isCreatingNewBranch) {
    if (state.newBranchName === '') {
      return getters.placeholderBranchName;
    }

    return state.newBranchName;
  }

  return rootState.currentBranchId;
};

export const preBuiltCommitMessage = (state, _, rootState) => {
  if (state.commitMessage) return state.commitMessage;

  const files = rootState.stagedFiles.length ? rootState.stagedFiles : rootState.changedFiles;
  const modifiedFiles = files.filter((f) => !f.deleted);
  const deletedFiles = files.filter((f) => f.deleted);

  return [
    createTranslatedTextForFiles(modifiedFiles, __('Update')),
    createTranslatedTextForFiles(deletedFiles, __('Deleted')),
  ]
    .filter((t) => t)
    .join('\n');
};

export const isCreatingNewBranch = (state) => state.commitAction === COMMIT_TO_NEW_BRANCH;

// eslint-disable-next-line max-params
export const shouldHideNewMrOption = (_state, getters, _rootState, rootGetters) =>
  !getters.isCreatingNewBranch &&
  (rootGetters.hasMergeRequest ||
    (!rootGetters.hasMergeRequest && rootGetters.isOnDefaultBranch)) &&
  rootGetters.canPushToBranch;

// eslint-disable-next-line max-params
export const shouldDisableNewMrOption = (state, getters, rootState, rootGetters) =>
  !rootGetters.canCreateMergeRequests || rootGetters.emptyRepo;

export const shouldCreateMR = (state, getters) =>
  state.shouldCreateMR && !getters.shouldDisableNewMrOption;

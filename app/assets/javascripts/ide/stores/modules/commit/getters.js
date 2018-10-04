import { sprintf, n__, __ } from '../../../../locale';
import * as consts from './constants';

const BRANCH_SUFFIX_COUNT = 5;
const createTranslatedTextForFiles = (files, text) => {
  if (!files.length) return null;

  return sprintf(n__('%{text} %{files}', '%{text} %{files} files', files.length), {
    files: files.reduce((acc, val) => acc.concat(val.path), []).join(', '),
    text,
  });
};

export const discardDraftButtonDisabled = state =>
  state.commitMessage === '' || state.submitCommitLoading;

export const newBranchName = (state, _, rootState) =>
  `${gon.current_username}-${rootState.currentBranchId}-patch-${`${new Date().getTime()}`.substr(
    -BRANCH_SUFFIX_COUNT,
  )}`;

export const branchName = (state, getters, rootState) => {
  if (
    state.commitAction === consts.COMMIT_TO_NEW_BRANCH ||
    state.commitAction === consts.COMMIT_TO_NEW_BRANCH_MR
  ) {
    if (state.newBranchName === '') {
      return getters.newBranchName;
    }

    return state.newBranchName;
  }

  return rootState.currentBranchId;
};

export const preBuiltCommitMessage = (state, _, rootState) => {
  if (state.commitMessage) return state.commitMessage;

  const files = rootState.stagedFiles.length ? rootState.stagedFiles : rootState.changedFiles;
  const modifiedFiles = files.filter(f => !f.deleted);
  const deletedFiles = files.filter(f => f.deleted);

  return [
    createTranslatedTextForFiles(modifiedFiles, __('Update')),
    createTranslatedTextForFiles(deletedFiles, __('Deleted')),
  ]
    .filter(t => t)
    .join('\n');
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

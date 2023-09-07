import { escape } from 'lodash';
import { __ } from '~/locale';
import { COMMIT_TO_NEW_BRANCH } from '../stores/modules/commit/constants';

const CODEOWNERS_REGEX = /Push.*protected branches.*CODEOWNERS/;
const BRANCH_CHANGED_REGEX = /changed.*since.*start.*edit/;
const BRANCH_ALREADY_EXISTS = /branch.*already.*exists/;

const createNewBranchAndCommit = (store) =>
  store
    .dispatch('commit/updateCommitAction', COMMIT_TO_NEW_BRANCH)
    .then(() => store.dispatch('commit/commitChanges'));

export const createUnexpectedCommitError = (message) => ({
  title: __('Unexpected error'),
  messageHTML: escape(message) || __('Could not commit. An unexpected error occurred.'),
});

export const createCodeownersCommitError = (message) => ({
  title: __('CODEOWNERS rule violation'),
  messageHTML: escape(message),
  primaryAction: {
    text: __('Create new branch'),
    callback: createNewBranchAndCommit,
  },
});

export const createBranchChangedCommitError = (message) => ({
  title: __('Branch changed'),
  messageHTML: `${escape(message)}<br/><br/>${__('Would you like to create a new branch?')}`,
  primaryAction: {
    text: __('Create new branch'),
    callback: createNewBranchAndCommit,
  },
});

export const branchAlreadyExistsCommitError = (message) => ({
  title: __('Branch already exists'),
  messageHTML: `${escape(message)}<br/><br/>${__(
    'Would you like to try auto-generating a branch name?',
  )}`,
  primaryAction: {
    text: __('Create new branch'),
    callback: (store) =>
      store.dispatch('commit/addSuffixToBranchName').then(() => createNewBranchAndCommit(store)),
  },
});

export const parseCommitError = (e) => {
  const { message } = e?.response?.data || {};

  if (!message) {
    return createUnexpectedCommitError();
  }

  if (CODEOWNERS_REGEX.test(message)) {
    return createCodeownersCommitError(message);
  }
  if (BRANCH_CHANGED_REGEX.test(message)) {
    return createBranchChangedCommitError(message);
  }
  if (BRANCH_ALREADY_EXISTS.test(message)) {
    return branchAlreadyExistsCommitError(message);
  }

  return createUnexpectedCommitError(message);
};

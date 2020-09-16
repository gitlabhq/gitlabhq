import { escape } from 'lodash';
import { __ } from '~/locale';

const CODEOWNERS_REGEX = /Push.*protected branches.*CODEOWNERS/;
const BRANCH_CHANGED_REGEX = /changed.*since.*start.*edit/;

export const createUnexpectedCommitError = () => ({
  title: __('Unexpected error'),
  messageHTML: __('Could not commit. An unexpected error occurred.'),
  canCreateBranch: false,
});

export const createCodeownersCommitError = message => ({
  title: __('CODEOWNERS rule violation'),
  messageHTML: escape(message),
  canCreateBranch: true,
});

export const createBranchChangedCommitError = message => ({
  title: __('Branch changed'),
  messageHTML: `${escape(message)}<br/><br/>${__('Would you like to create a new branch?')}`,
  canCreateBranch: true,
});

export const parseCommitError = e => {
  const { message } = e?.response?.data || {};

  if (!message) {
    return createUnexpectedCommitError();
  }

  if (CODEOWNERS_REGEX.test(message)) {
    return createCodeownersCommitError(message);
  } else if (BRANCH_CHANGED_REGEX.test(message)) {
    return createBranchChangedCommitError(message);
  }

  return createUnexpectedCommitError();
};

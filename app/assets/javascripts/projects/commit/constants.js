import { s__, __ } from '~/locale';

export const OPEN_REVERT_MODAL = 'openRevertModal';
export const REVERT_MODAL_ID = 'revert-commit-modal';
export const OPEN_CHERRY_PICK_MODAL = 'openCherryPickModal';
export const CHERRY_PICK_MODAL_ID = 'cherry-pick-commit-modal';

export const I18N_MODAL = {
  startMergeRequest: s__('ChangeTypeAction|Start a %{newMergeRequest} with these changes'),
  existingBranch: s__(
    'ChangeTypeAction|Your changes will be committed to %{branchName} because a merge request is open.',
  ),
  branchInFork: s__(
    'ChangeTypeAction|A new branch will be created in your fork and a new merge request will be started.',
  ),
  newMergeRequest: __('new merge request'),
  actionCancelText: __('Cancel'),
};

export const I18N_REVERT_MODAL = {
  branchLabel: s__('ChangeTypeAction|Revert in branch'),
  actionPrimaryText: s__('ChangeTypeAction|Revert'),
};

export const I18N_CHERRY_PICK_MODAL = {
  branchLabel: s__('ChangeTypeAction|Pick into branch'),
  projectLabel: s__('ChangeTypeAction|Pick into project'),
  actionPrimaryText: s__('ChangeTypeAction|Cherry-pick'),
};

export const PREPENDED_MODAL_TEXT = s__(
  'ChangeTypeAction|This will create a new commit in order to revert the existing changes.',
);

export const I18N_NO_RESULTS_MESSAGE = __('No matching results');

export const I18N_PROJECT_HEADER = s__('ChangeTypeAction|Switch project');
export const I18N_PROJECT_SEARCH_PLACEHOLDER = s__('ChangeTypeAction|Search projects');

export const I18N_BRANCH_HEADER = s__('ChangeTypeAction|Switch branch');
export const I18N_BRANCH_SEARCH_PLACEHOLDER = s__('ChangeTypeAction|Search branches');

export const PROJECT_BRANCHES_ERROR = __('Something went wrong while fetching branches');

import { I18N_MODAL } from '~/projects/commit/constants';

export default {
  mockModal: {
    modalTitle: '_modal_title_',
    endpoint: '_endpoint_',
    branch: '_branch_',
    pushCode: true,
    defaultBranch: '_branch_',
    existingBranch: '_existing_branch',
    branchesEndpoint: '_branches_endpoint_',
  },
  modalPropsData: {
    i18n: {
      branchLabel: '_branch_label_',
      actionPrimaryText: '_action_primary_text_',
      startMergeRequest: '_start_merge_request_',
      existingBranch: I18N_MODAL.existingBranch,
      branchInFork: '_new_branch_in_fork_message_',
      newMergeRequest: '_new merge request_',
      actionCancelText: '_action_cancel_text_',
    },
    modalId: '_modal_id_',
    openModal: '_open_modal_',
  },
  mockBranches: ['_branch_1', '_abc_', '_main_'],
  mockProjects: [
    { id: 1, name: '_project_1', refsUrl: '/_project_1/refs' },
    { id: 2, name: '_abc_', refsUrl: '/_abc_/refs' },
    { id: 3, name: '_project_', refsUrl: '/_project_/refs' },
  ],
};

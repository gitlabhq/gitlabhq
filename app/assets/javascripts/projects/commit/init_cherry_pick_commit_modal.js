import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { pinia } from '~/pinia/instance';
import CommitFormModal from './components/form_modal.vue';
import {
  I18N_MODAL,
  I18N_CHERRY_PICK_MODAL,
  OPEN_CHERRY_PICK_MODAL,
  CHERRY_PICK_MODAL_ID,
} from './constants';
import { useCherryPickCommit } from './store/cherry_pick_commit';

export default function initInviteMembersModal(primaryActionEventName) {
  const el = document.querySelector('.js-cherry-pick-commit-modal');
  if (!el) {
    return false;
  }

  const {
    title,
    endpoint,
    branch,
    targetProjectId,
    targetProjectName,
    pushCode,
    branchCollaboration,
    existingBranch,
    branchesEndpoint,
    projects,
  } = el.dataset;

  const modalStore = useCherryPickCommit(pinia);
  modalStore.$patch({
    endpoint,
    branchesEndpoint,
    branch,
    targetProjectId,
    targetProjectName,
    pushCode: parseBoolean(pushCode),
    branchCollaboration: parseBoolean(branchCollaboration),
    defaultBranch: branch,
    modalTitle: title,
    existingBranch,
    projects: convertObjectPropsToCamelCase(JSON.parse(projects), { deep: true }),
  });

  return new Vue({
    el,
    name: 'CommitFormModalRoot',
    pinia,
    provide: {
      modalStore,
    },
    render: (createElement) =>
      createElement(CommitFormModal, {
        props: {
          i18n: { ...I18N_CHERRY_PICK_MODAL, ...I18N_MODAL },
          openModal: OPEN_CHERRY_PICK_MODAL,
          modalId: CHERRY_PICK_MODAL_ID,
          isCherryPick: true,
          primaryActionEventName,
        },
      }),
  });
}

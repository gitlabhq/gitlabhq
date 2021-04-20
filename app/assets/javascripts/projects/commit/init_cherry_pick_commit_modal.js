import Vue from 'vue';
import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import CommitFormModal from './components/form_modal.vue';
import {
  I18N_MODAL,
  I18N_CHERRY_PICK_MODAL,
  OPEN_CHERRY_PICK_MODAL,
  CHERRY_PICK_MODAL_ID,
} from './constants';
import createStore from './store';

export default function initInviteMembersModal() {
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

  const store = createStore({
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
    store,
    render: (createElement) =>
      createElement(CommitFormModal, {
        props: {
          i18n: { ...I18N_CHERRY_PICK_MODAL, ...I18N_MODAL },
          openModal: OPEN_CHERRY_PICK_MODAL,
          modalId: CHERRY_PICK_MODAL_ID,
          isCherryPick: true,
        },
      }),
  });
}

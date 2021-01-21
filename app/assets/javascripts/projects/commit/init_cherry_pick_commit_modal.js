import Vue from 'vue';
import CommitFormModal from './components/form_modal.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './store';
import {
  I18N_MODAL,
  I18N_CHERRY_PICK_MODAL,
  OPEN_CHERRY_PICK_MODAL,
  CHERRY_PICK_MODAL_ID,
} from './constants';

export default function initInviteMembersModal() {
  const el = document.querySelector('.js-cherry-pick-commit-modal');
  if (!el) {
    return false;
  }

  const {
    title,
    endpoint,
    branch,
    pushCode,
    branchCollaboration,
    existingBranch,
    branchesEndpoint,
  } = el.dataset;

  const store = createStore({
    endpoint,
    branchesEndpoint,
    branch,
    pushCode: parseBoolean(pushCode),
    branchCollaboration: parseBoolean(branchCollaboration),
    defaultBranch: branch,
    modalTitle: title,
    existingBranch,
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
        },
      }),
  });
}

import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CommitFormModal from './components/form_modal.vue';
import {
  I18N_MODAL,
  I18N_REVERT_MODAL,
  PREPENDED_MODAL_TEXT,
  OPEN_REVERT_MODAL,
  REVERT_MODAL_ID,
} from './constants';
import createStore from './store';

export default function initInviteMembersModal(primaryActionEventName) {
  const el = document.querySelector('.js-revert-commit-modal');
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
    provide: {
      prependedText: PREPENDED_MODAL_TEXT,
    },
    render: (createElement) =>
      createElement(CommitFormModal, {
        props: {
          i18n: { ...I18N_REVERT_MODAL, ...I18N_MODAL },
          openModal: OPEN_REVERT_MODAL,
          modalId: REVERT_MODAL_ID,
          primaryActionEventName,
        },
      }),
  });
}

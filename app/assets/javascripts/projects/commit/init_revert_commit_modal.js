import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import { pinia } from '~/pinia/instance';
import CommitFormModal from './components/form_modal.vue';
import {
  I18N_MODAL,
  I18N_REVERT_MODAL,
  PREPENDED_MODAL_TEXT,
  OPEN_REVERT_MODAL,
  REVERT_MODAL_ID,
} from './constants';
import { useRevertCommit } from './store/revert_commit';

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

  const modalStore = useRevertCommit(pinia);
  modalStore.$patch({
    endpoint,
    branchesEndpoint,
    branch,
    pushCode: parseBoolean(pushCode),
    branchCollaboration: parseBoolean(branchCollaboration),
    defaultBranch: branch,
    modalTitle: title,
    existingBranch,
  });

  return initVueApp({
    el,
    name: 'CommitFormModalRoot',
    pinia,
    provide: {
      modalStore,
      prependedText: PREPENDED_MODAL_TEXT,
    },
    component: CommitFormModal,
    props: {
      i18n: { ...I18N_REVERT_MODAL, ...I18N_MODAL },
      openModal: OPEN_REVERT_MODAL,
      modalId: REVERT_MODAL_ID,
      primaryActionEventName,
    },
  });
}

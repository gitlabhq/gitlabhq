import Vue from 'vue';
import CommitFormTrigger from './components/form_trigger.vue';
import { OPEN_REVERT_MODAL, REVERT_LINK_TEST_ID } from './constants';

export default function initInviteMembersTrigger() {
  const el = document.querySelector('.js-revert-commit-trigger');

  if (!el) {
    return false;
  }

  const { displayText } = el.dataset;

  return new Vue({
    el,
    provide: { displayText, testId: REVERT_LINK_TEST_ID },
    render: (createElement) =>
      createElement(CommitFormTrigger, { props: { openModal: OPEN_REVERT_MODAL } }),
  });
}

import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import InviteMemberModal from './components/invite_member_modal.vue';

Vue.use(GlToast);

export default function initInviteMembersModal() {
  const el = document.querySelector('.js-invite-member-modal');

  if (!el) {
    return false;
  }

  const { membersPath } = el.dataset;

  return new Vue({
    el,
    provide: { membersPath },
    render: createElement => createElement(InviteMemberModal),
  });
}

import Vue from 'vue';
import InviteMemberTrigger from './components/invite_member_trigger.vue';

export default function initInviteMembersTrigger() {
  const el = document.querySelector('.js-invite-member-trigger');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    provide: { ...el.dataset },
    render: createElement => createElement(InviteMemberTrigger),
  });
}

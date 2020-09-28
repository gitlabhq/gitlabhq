import Vue from 'vue';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

export default function initInviteMembersTrigger() {
  const el = document.querySelector('.js-invite-members-trigger');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render: createElement =>
      createElement(InviteMembersTrigger, {
        props: {
          ...el.dataset,
        },
      }),
  });
}

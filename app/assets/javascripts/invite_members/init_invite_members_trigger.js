import Vue from 'vue';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

export default function initInviteMembersTrigger() {
  const triggers = document.querySelectorAll('.js-invite-members-trigger');

  if (!triggers) {
    return false;
  }

  return triggers.forEach((el) => {
    return new Vue({
      el,
      render: (createElement) =>
        createElement(InviteMembersTrigger, {
          props: {
            ...el.dataset,
          },
        }),
    });
  });
}

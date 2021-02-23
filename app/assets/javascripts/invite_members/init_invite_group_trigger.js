import Vue from 'vue';
import InviteGroupTrigger from '~/invite_members/components/invite_group_trigger.vue';

export default function initInviteGroupTrigger() {
  const el = document.querySelector('.js-invite-group-trigger');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render: (createElement) =>
      createElement(InviteGroupTrigger, {
        props: {
          ...el.dataset,
        },
      }),
  });
}

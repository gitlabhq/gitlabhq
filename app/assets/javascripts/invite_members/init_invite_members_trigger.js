import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';

export default function initInviteMembersTrigger() {
  const triggers = document.querySelectorAll('.js-invite-members-trigger');

  if (!triggers) {
    return false;
  }

  return triggers.forEach((el) => {
    return initVueApp({
      el,
      name: 'InviteMembersTriggerRoot',
      component: InviteMembersTrigger,
      props: {
        ...el.dataset,
      },
    });
  });
}

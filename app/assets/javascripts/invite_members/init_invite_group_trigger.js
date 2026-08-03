import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import InviteGroupTrigger from '~/invite_members/components/invite_group_trigger.vue';

export default function initInviteGroupTrigger() {
  const el = document.querySelector('.js-invite-group-trigger');

  if (!el) {
    return false;
  }

  return initVueApp({
    el,
    name: 'InviteGroupTriggerRoot',
    component: InviteGroupTrigger,
    props: {
      ...el.dataset,
    },
  });
}

import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ImportProjectMembersTrigger from '~/invite_members/components/import_project_members_trigger.vue';

export default function initImportProjectMembersTrigger() {
  const el = document.querySelector('.js-import-project-members-trigger');

  if (!el) {
    return false;
  }

  return initVueApp({
    el,
    name: 'ImportProjectMembersTriggerRoot',
    component: ImportProjectMembersTrigger,
    props: {
      ...el.dataset,
    },
  });
}

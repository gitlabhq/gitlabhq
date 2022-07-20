import Vue from 'vue';
import ImportProjectMembersTrigger from '~/invite_members/components/import_project_members_trigger.vue';

export default function initImportProjectMembersTrigger() {
  const el = document.querySelector('.js-import-project-members-trigger');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render: (createElement) =>
      createElement(ImportProjectMembersTrigger, {
        props: {
          ...el.dataset,
        },
      }),
  });
}

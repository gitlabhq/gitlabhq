import Vue from 'vue';
import ImportProjectMembersModal from '~/invite_members/components/import_project_members_modal.vue';

export default function initImportProjectMembersModal() {
  const el = document.querySelector('.js-import-project-members-modal');

  if (!el) {
    return false;
  }

  const { projectId, projectName } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(ImportProjectMembersModal, {
        props: {
          projectId,
          projectName,
        },
      }),
  });
}

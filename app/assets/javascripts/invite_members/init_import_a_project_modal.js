import Vue from 'vue';
import ImportAProjectModal from '~/invite_members/components/import_a_project_modal.vue';

export default function initImportAProjectModal() {
  const el = document.querySelector('.js-import-a-project-modal');

  if (!el) {
    return false;
  }

  const { projectId, projectName } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(ImportAProjectModal, {
        props: {
          projectId,
          projectName,
        },
      }),
  });
}

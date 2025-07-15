import Vue from 'vue';

import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import csrf from '~/lib/utils/csrf';
import Translate from '~/vue_shared/translate';
import { initAdminProjects } from '~/admin/projects/index';

import deleteProjectModal from './components/delete_project_modal.vue';

// To be removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/549452
const initDeleteProjectModal = () => {
  const deleteProjectModalEl = document.getElementById('delete-project-modal');

  if (!deleteProjectModalEl) return;

  Vue.use(Translate);

  const deleteModal = new Vue({
    el: deleteProjectModalEl,
    data() {
      return {
        deleteProjectUrl: '',
        projectName: '',
      };
    },
    mounted() {
      const deleteProjectButtons = document.querySelectorAll('.delete-project-button');
      deleteProjectButtons.forEach((button) => {
        button.addEventListener('click', () => {
          const buttonProps = button.dataset;
          deleteModal.deleteProjectUrl = buttonProps.deleteProjectUrl;
          deleteModal.projectName = buttonProps.projectName;

          this.$root.$emit(BV_SHOW_MODAL, 'delete-project-modal');
        });
      });
    },
    render(createElement) {
      return createElement(deleteProjectModal, {
        props: {
          deleteProjectUrl: this.deleteProjectUrl,
          projectName: this.projectName,
          csrfToken: csrf.token,
        },
      });
    },
  });
};

initDeleteProjectModal();
initAdminProjects();

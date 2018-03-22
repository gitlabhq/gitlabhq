import $ from 'jquery';
import Vue from 'vue';

import Translate from '~/vue_shared/translate';
import csrf from '~/lib/utils/csrf';

import deleteProjectModal from './components/delete_project_modal.vue';

document.addEventListener('DOMContentLoaded', () => {
  Vue.use(Translate);

  const deleteProjectModalEl = document.getElementById('delete-project-modal');

  const deleteModal = new Vue({
    el: deleteProjectModalEl,
    data: {
      deleteProjectUrl: '',
      projectName: '',
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

  $(document).on('shown.bs.modal', (event) => {
    if (event.relatedTarget.classList.contains('delete-project-button')) {
      const buttonProps = event.relatedTarget.dataset;
      deleteModal.deleteProjectUrl = buttonProps.deleteProjectUrl;
      deleteModal.projectName = buttonProps.projectName;
    }
  });
});

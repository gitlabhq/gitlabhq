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
    mounted() {
      const deleteProjectButtons = document.querySelectorAll('.delete-project-button');
      deleteProjectButtons.forEach(button => {
        button.addEventListener('click', () => {
          const buttonProps = button.dataset;
          deleteModal.deleteProjectUrl = buttonProps.deleteProjectUrl;
          deleteModal.projectName = buttonProps.projectName;

          this.$root.$emit('bv::show::modal', 'delete-project-modal');
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
});

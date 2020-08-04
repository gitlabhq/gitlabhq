import Vue from 'vue';
import ProjectDeleteButton from './components/project_delete_button.vue';

export default (selector = '#js-project-delete-button') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const { confirmPhrase, formPath } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(ProjectDeleteButton, {
        props: {
          confirmPhrase,
          formPath,
        },
      });
    },
  });
};

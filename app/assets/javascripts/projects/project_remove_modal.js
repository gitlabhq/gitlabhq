import Vue from 'vue';
import RemoveProjectModal from './components/remove_modal.vue';

export default (selector = '#js-confirm-project-remove') => {
  const el = document.querySelector(selector);

  if (!el) return;

  const { formPath, confirmPhrase, warningMessage } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(RemoveProjectModal, {
        props: {
          confirmPhrase,
          warningMessage,
          formPath,
        },
      });
    },
  });
};

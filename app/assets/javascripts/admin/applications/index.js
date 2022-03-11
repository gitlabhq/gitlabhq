import Vue from 'vue';
import DeleteApplication from './components/delete_application.vue';

export default () => {
  const el = document.querySelector('.js-application-delete-modal');

  if (!el) return false;

  return new Vue({
    el,
    render(h) {
      return h(DeleteApplication);
    },
  });
};

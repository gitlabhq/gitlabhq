import Vue from 'vue';
import UpdateSharedRunnersForm from './components/shared_runners_form.vue';

export default (containerId = 'update-shared-runners-form') => {
  const containerEl = document.getElementById(containerId);

  return new Vue({
    el: containerEl,
    render(createElement) {
      return createElement(UpdateSharedRunnersForm, {
        props: containerEl.dataset,
      });
    },
  });
};

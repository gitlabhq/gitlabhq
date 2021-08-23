import Vue from 'vue';
import StorageCounterApp from './components/app.vue';

export default (containerId = 'js-project-storage-count-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(StorageCounterApp);
    },
  });
};

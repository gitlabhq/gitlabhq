import Vue from 'vue';
import ImportDetailsApp from './components/import_details_app.vue';

export default () => {
  const el = document.querySelector('.js-import-details');

  if (!el) {
    return null;
  }

  const { failuresPath } = el.dataset;

  return new Vue({
    el,
    name: 'ImportDetailsRoot',
    provide: {
      failuresPath,
    },
    render(createElement) {
      return createElement(ImportDetailsApp);
    },
  });
};

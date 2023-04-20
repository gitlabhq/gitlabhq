import Vue from 'vue';
import ImportDetailsApp from './components/import_details_app.vue';

export default () => {
  const el = document.querySelector('.js-import-details');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'ImportDetailsRoot',
    render(createElement) {
      return createElement(ImportDetailsApp);
    },
  });
};

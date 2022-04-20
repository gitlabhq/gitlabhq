import Vue from 'vue';
import ImportHistoryApp from './components/import_history_app.vue';

function mountImportHistoryApp(mountElement) {
  if (!mountElement) return undefined;

  return new Vue({
    el: mountElement,
    name: 'ImportHistoryRoot',
    provide: {
      assets: {
        gitlabLogo: mountElement.dataset.logo,
      },
    },
    render(createElement) {
      return createElement(ImportHistoryApp);
    },
  });
}

mountImportHistoryApp(document.querySelector('#import-history-mount-element'));

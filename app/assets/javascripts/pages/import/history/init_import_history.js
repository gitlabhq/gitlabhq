import Vue from 'vue';
import ImportHistoryApp from './components/import_history_app.vue';

export function initImportHistory() {
  const el = document.querySelector('#import-history-mount-element');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'ImportHistoryRoot',
    provide: {
      assets: {
        gitlabLogo: el.dataset.logo,
      },
    },
    render(createElement) {
      return createElement(ImportHistoryApp);
    },
  });
}

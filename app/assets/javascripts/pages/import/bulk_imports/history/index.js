import Vue from 'vue';
import BulkImportHistoryApp from './components/bulk_imports_history_app.vue';

function mountImportHistoryApp(mountElement) {
  if (!mountElement) return undefined;

  return new Vue({
    el: mountElement,
    render(createElement) {
      return createElement(BulkImportHistoryApp);
    },
  });
}

mountImportHistoryApp(document.querySelector('#import-history-mount-element'));

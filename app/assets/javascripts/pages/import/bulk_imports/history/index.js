import Vue from 'vue';
import BulkImportHistoryApp from './components/bulk_imports_history_app.vue';

function mountImportHistoryApp(mountElement) {
  if (!mountElement) return undefined;

  const { realtimeChangesPath } = mountElement.dataset;

  return new Vue({
    el: mountElement,
    name: 'BulkImportHistoryRoot',
    provide: {
      realtimeChangesPath,
    },
    render(createElement) {
      return createElement(BulkImportHistoryApp);
    },
  });
}

mountImportHistoryApp(document.querySelector('#import-history-mount-element'));

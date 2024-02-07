import Vue from 'vue';
import BulkImportHistoryApp from './components/bulk_imports_history_app.vue';

function mountImportHistoryApp(mountElement) {
  if (!mountElement) return undefined;

  const { id, realtimeChangesPath, detailsPath } = mountElement.dataset;

  return new Vue({
    el: mountElement,
    name: 'BulkImportHistoryRoot',
    provide: {
      realtimeChangesPath,
      detailsPath,
    },
    render(createElement) {
      return createElement(BulkImportHistoryApp, {
        props: {
          id,
        },
      });
    },
  });
}

mountImportHistoryApp(document.querySelector('#import-history-mount-element'));

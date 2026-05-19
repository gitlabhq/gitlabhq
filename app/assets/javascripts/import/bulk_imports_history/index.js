import Vue from 'vue';
import BulkImportHistoryApp from './components/bulk_imports_history_app.vue';

export function initBulkImportHistory() {
  const el = document.querySelector('#import-history-mount-element');

  if (!el) {
    return null;
  }

  const { id, realtimeChangesPath, detailsPath } = el.dataset;

  return new Vue({
    el,
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

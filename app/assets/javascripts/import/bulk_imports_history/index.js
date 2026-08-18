import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import BulkImportHistoryApp from './components/bulk_imports_history_app.vue';

export function initBulkImportHistory() {
  const el = document.querySelector('#import-history-mount-element');

  if (!el) {
    return null;
  }

  const { id, realtimeChangesPath, detailsPath } = el.dataset;

  return initVueApp({
    el,
    name: 'BulkImportHistoryRoot',
    provide: {
      realtimeChangesPath,
      detailsPath,
    },
    component: BulkImportHistoryApp,
    props: {
      id,
    },
  });
}

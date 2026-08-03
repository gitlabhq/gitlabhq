import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import BulkImportDetailsApp from './components/bulk_import_details_app.vue';
import ImportDetailsApp from './components/import_details_app.vue';

export default () => {
  const el = document.querySelector('.js-import-details');

  if (!el) {
    return null;
  }

  const { failuresPath } = el.dataset;

  return initVueApp({
    el,
    name: 'ImportDetailsRoot',
    provide: {
      failuresPath,
    },
    component: ImportDetailsApp,
  });
};

export const initBulkImportDetails = () => {
  const el = document.querySelector('.js-bulk-import-details');

  if (!el) {
    return null;
  }

  const { id, entityId, fullPath } = el.dataset;

  return initVueApp({
    el,
    name: 'BulkImportDetailsRoot',
    component: BulkImportDetailsApp,
    props: {
      id,
      entityId,
      fullPath,
    },
  });
};

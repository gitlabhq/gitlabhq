import Vue from 'vue';
import BulkImportDetailsApp from './components/bulk_import_details_app.vue';
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

export const initBulkImportDetails = () => {
  const el = document.querySelector('.js-bulk-import-details');

  if (!el) {
    return null;
  }

  const { id, entityId, fullPath } = el.dataset;

  return new Vue({
    el,
    name: 'BulkImportDetailsRoot',
    render(createElement) {
      return createElement(BulkImportDetailsApp, {
        props: {
          id,
          entityId,
          fullPath,
        },
      });
    },
  });
};

import Vue from 'vue';
import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';

export const initBulkImportDetails = () => {
  const el = document.querySelector('.js-bulk-import-details');

  if (!el) {
    return null;
  }

  const { failuresPath } = el.dataset;

  return new Vue({
    el,
    name: 'BulkImportDetailsRoot',
    provide: {
      failuresPath,
    },
    render(createElement) {
      return createElement(BulkImportDetailsApp);
    },
  });
};

initBulkImportDetails();

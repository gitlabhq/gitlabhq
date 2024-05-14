import Vue from 'vue';
import { initBulkImportDetails } from '~/pages/import/bulk_imports/failures/index';

jest.mock('~/import/details/components/bulk_import_details_app.vue');

describe('initBulkImportDetails', () => {
  let appRoot;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('class', 'js-bulk-import-details');
    document.body.appendChild(appRoot);
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  describe('when there is no app root', () => {
    it('returns null', () => {
      expect(initBulkImportDetails()).toBeNull();
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('returns a Vue instance', () => {
      expect(initBulkImportDetails()).toBeInstanceOf(Vue);
    });
  });
});

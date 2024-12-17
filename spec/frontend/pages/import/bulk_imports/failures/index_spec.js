import { createWrapper } from '@vue/test-utils';
import { initBulkImportDetails } from '~/pages/import/bulk_imports/failures';
import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';

jest.mock('~/import/details/components/bulk_import_details_app.vue');

describe('initBulkImportDetails', () => {
  let appRoot;
  let wrapper;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('class', 'js-bulk-import-details');
    document.body.appendChild(appRoot);

    wrapper = createWrapper(initBulkImportDetails());
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  const findBulkImportDetailsApp = () => wrapper.findComponent(BulkImportDetailsApp);

  describe('when there is no app root', () => {
    it('returns null', () => {
      expect(initBulkImportDetails()).toBeNull();
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('renders the app', () => {
      expect(findBulkImportDetailsApp().exists()).toBe(true);
    });
  });
});

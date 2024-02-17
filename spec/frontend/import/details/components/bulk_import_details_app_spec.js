import { shallowMount } from '@vue/test-utils';

import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';
import ImportDetailsTable from '~/import/details/components/import_details_table.vue';

jest.mock('~/lib/utils/url_utility');

describe('Bulk import details app', () => {
  let wrapper;

  const mockId = '151';
  const mockEntityId = '46584';
  const defaultProps = {
    id: mockId,
    entityId: mockEntityId,
  };

  const createComponent = () => {
    wrapper = shallowMount(BulkImportDetailsApp, {
      propsData: { ...defaultProps },
    });
  };

  const findImportTable = () => wrapper.findComponent(ImportDetailsTable);

  describe('template', () => {
    it('renders heading', () => {
      createComponent();

      const headingText = wrapper.find('h1').text();

      expect(headingText).toBe(`Items that failed to be imported for ${mockEntityId}`);
    });

    it('renders import table', () => {
      createComponent();

      expect(findImportTable().props()).toMatchObject({
        id: mockId,
        bulkImport: true,
        entityId: mockEntityId,
      });
    });
  });
});

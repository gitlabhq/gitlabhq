import { shallowMount } from '@vue/test-utils';
import { getParameterValues } from '~/lib/utils/url_utility';

import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';

jest.mock('~/lib/utils/url_utility');

describe('Bulk import details app', () => {
  let wrapper;

  const mockId = 151;

  const createComponent = () => {
    wrapper = shallowMount(BulkImportDetailsApp);
  };

  beforeEach(() => {
    getParameterValues.mockReturnValueOnce([mockId]);
  });

  describe('template', () => {
    it('renders heading', () => {
      createComponent();

      const headingText = wrapper.find('h1').text();

      expect(headingText).toBe(`Items that failed to be imported for ${mockId}`);
    });
  });
});

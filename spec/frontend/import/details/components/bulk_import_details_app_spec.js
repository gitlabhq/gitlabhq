import { shallowMount } from '@vue/test-utils';
import BulkImportDetailsApp from '~/import/details/components/bulk_import_details_app.vue';

describe('Bulk import details app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BulkImportDetailsApp);
  };

  describe('template', () => {
    it('renders heading', () => {
      createComponent();

      expect(wrapper.find('h1').text()).toBe('GitLab Migration details');
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import ImportDetailsApp from '~/import/details/components/import_details_app.vue';

describe('Import details app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ImportDetailsApp);
  };

  describe('template', () => {
    it('renders heading', () => {
      createComponent();

      expect(wrapper.find('h1').text()).toBe('GitHub import details');
    });
  });
});

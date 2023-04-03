import { shallowMount } from '@vue/test-utils';
import ImportDetailsApp from '~/import/details/components/import_details_app.vue';
import { mockProject } from '../mock_data';

describe('Import details app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ImportDetailsApp, {
      propsData: {
        project: mockProject,
      },
    });
  };

  describe('template', () => {
    it('renders heading', () => {
      createComponent();

      expect(wrapper.find('h1').text()).toBe(ImportDetailsApp.i18n.pageTitle);
    });
  });
});

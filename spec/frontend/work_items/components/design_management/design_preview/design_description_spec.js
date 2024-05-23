import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignDescription from '~/work_items/components/design_management/design_preview/design_description.vue';
import mockDesign from './mock_design';

describe('DesignDescription', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMountExtended(DesignDescription, {
      propsData: {
        design: mockDesign,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders design description', () => {
    expect(wrapper.findByTestId('design-description-content').text()).toBe(
      mockDesign.descriptionHtml,
    );
  });
});

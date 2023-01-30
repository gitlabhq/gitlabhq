import { shallowMount } from '@vue/test-utils';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter.vue';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';

describe('ConfidentialityFilter', () => {
  let wrapper;

  const createComponent = (initProps) => {
    wrapper = shallowMount(ConfidentialityFilter, {
      ...initProps,
    });
  };

  const findRadioFilter = () => wrapper.findComponent(RadioFilter);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the component', () => {
      expect(findRadioFilter().exists()).toBe(true);
    });
  });
});

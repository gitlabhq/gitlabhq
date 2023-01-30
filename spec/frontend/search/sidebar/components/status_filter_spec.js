import { shallowMount } from '@vue/test-utils';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

describe('StatusFilter', () => {
  let wrapper;

  const createComponent = (initProps) => {
    wrapper = shallowMount(StatusFilter, {
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

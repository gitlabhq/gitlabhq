import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MaskedValue from '~/runner/components/helpers/masked_value.vue';

const mockSecret = '01234567890';
const mockMasked = '***********';

describe('MaskedValue', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(MaskedValue, {
      propsData: {
        value: mockSecret,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays masked value by default', () => {
    expect(wrapper.text()).toBe(mockMasked);
  });

  describe('When the icon is clicked', () => {
    beforeEach(() => {
      findButton().vm.$emit('click');
    });

    it('Displays the actual value', () => {
      expect(wrapper.text()).toBe(mockSecret);
      expect(wrapper.text()).not.toBe(mockMasked);
    });

    it('When user clicks again, displays masked value', async () => {
      await findButton().vm.$emit('click');

      expect(wrapper.text()).toBe(mockMasked);
      expect(wrapper.text()).not.toBe(mockSecret);
    });
  });
});

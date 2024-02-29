import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DesignScaler from '~/design_management/components/design_scaler.vue';

describe('Design management design scaler component', () => {
  let wrapper;

  const getButtons = () => wrapper.findAllComponents(GlButton);
  const getDecreaseScaleButton = () => getButtons().at(0);
  const getIncreaseScaleButton = () => getButtons().at(1);
  const getScaleValue = () => wrapper.findByTestId('scale-value');

  const setScale = (scale) => wrapper.vm.setScale(scale);

  const createComponent = () => {
    wrapper = shallowMountExtended(DesignScaler, {
      propsData: {
        maxScale: 1.5,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the scale value', () => {
    expect(getScaleValue().exists()).toBe(true);
    expect(getScaleValue().text()).toBe('100%');
  });

  describe('when `scale` value is greater than 1', () => {
    beforeEach(async () => {
      // Mimic exact behaviour of zoom scaling
      // incrementing first and then decrementing
      await getIncreaseScaleButton().vm.$emit('click');
    });

    it('emits @scale event when "decrement" button clicked', async () => {
      expect(wrapper.emitted('scale')).toEqual([[1.1]]);
      expect(getScaleValue().text()).toBe('111%');

      await getDecreaseScaleButton().vm.$emit('click');

      expect(wrapper.emitted('scale')[1]).toEqual([1]);
      expect(getScaleValue().text()).toBe('100%');
    });

    it('enables the "decrement" button', () => {
      const decrementButton = getDecreaseScaleButton();

      expect(decrementButton.exists()).toBe(true);
      expect(decrementButton.props('disabled')).toBe(false);
    });
  });

  it('emits @scale event when "plus" button clicked', async () => {
    expect(getScaleValue().text()).toBe('100%');

    await getIncreaseScaleButton().vm.$emit('click');

    expect(wrapper.emitted('scale')).toEqual([[1.1]]);
    expect(getScaleValue().text()).toBe('111%');
  });

  it('computes & increments correct stepSize based on maxScale', async () => {
    wrapper.setProps({ maxScale: 11 });

    await nextTick();

    getIncreaseScaleButton().vm.$emit('click');

    await nextTick();

    expect(wrapper.emitted().scale[0][0]).toBe(3);
  });

  describe('when `scale` value is 1', () => {
    it('disables the "decrement" button', () => {
      const decrementButton = getDecreaseScaleButton();

      expect(decrementButton.exists()).toBe(true);
      expect(decrementButton.props('disabled')).toBe(true);
    });
  });

  describe('when `scale` value is maximum', () => {
    beforeEach(async () => {
      setScale(2);
      await nextTick();
    });

    it('disables the "increment" button', () => {
      const incrementButton = getIncreaseScaleButton();

      expect(incrementButton.exists()).toBe(true);
      expect(incrementButton.props('disabled')).toBe(true);
    });
  });
});

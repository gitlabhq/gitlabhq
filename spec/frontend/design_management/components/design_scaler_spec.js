import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DesignScaler from '~/design_management/components/design_scaler.vue';

describe('Design management design scaler component', () => {
  let wrapper;

  const getButtons = () => wrapper.findAllComponents(GlButton);
  const getDecreaseScaleButton = () => getButtons().at(0);
  const getResetScaleButton = () => getButtons().at(1);
  const getIncreaseScaleButton = () => getButtons().at(2);

  const setScale = (scale) => wrapper.vm.setScale(scale);

  const createComponent = () => {
    wrapper = shallowMount(DesignScaler, {
      propsData: {
        maxScale: 2,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when `scale` value is greater than 1', () => {
    beforeEach(async () => {
      setScale(1.6);
      await nextTick();
    });

    it('emits @scale event when "reset" button clicked', () => {
      getResetScaleButton().vm.$emit('click');
      expect(wrapper.emitted('scale')[1]).toEqual([1]);
    });

    it('emits @scale event when "decrement" button clicked', () => {
      getDecreaseScaleButton().vm.$emit('click');
      expect(wrapper.emitted('scale')[1]).toEqual([1.4]);
    });

    it('enables the "reset" button', () => {
      const resetButton = getResetScaleButton();

      expect(resetButton.exists()).toBe(true);
      expect(resetButton.props('disabled')).toBe(false);
    });

    it('enables the "decrement" button', () => {
      const decrementButton = getDecreaseScaleButton();

      expect(decrementButton.exists()).toBe(true);
      expect(decrementButton.props('disabled')).toBe(false);
    });
  });

  it('emits @scale event when "plus" button clicked', () => {
    getIncreaseScaleButton().vm.$emit('click');
    expect(wrapper.emitted('scale')).toEqual([[1.2]]);
  });

  it('computes & increments correct stepSize based on maxScale', async () => {
    wrapper.setProps({ maxScale: 11 });

    await nextTick();

    getIncreaseScaleButton().vm.$emit('click');

    await nextTick();

    expect(wrapper.emitted().scale[0][0]).toBe(3);
  });

  describe('when `scale` value is 1', () => {
    it('disables the "reset" button', () => {
      const resetButton = getResetScaleButton();

      expect(resetButton.exists()).toBe(true);
      expect(resetButton.props('disabled')).toBe(true);
    });

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

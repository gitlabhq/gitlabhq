import { shallowMount } from '@vue/test-utils';
import DesignScaler from '~/design_management/components/design_scaler.vue';

describe('Design management design scaler component', () => {
  let wrapper;

  function createComponent(propsData, data = {}) {
    wrapper = shallowMount(DesignScaler, {
      propsData,
    });
    wrapper.setData(data);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const getButton = type => {
    const buttonTypeOrder = ['minus', 'reset', 'plus'];
    const buttons = wrapper.findAll('button');
    return buttons.at(buttonTypeOrder.indexOf(type));
  };

  it('emits @scale event when "plus" button clicked', () => {
    createComponent();

    getButton('plus').trigger('click');
    expect(wrapper.emitted('scale')).toEqual([[1.2]]);
  });

  it('emits @scale event when "reset" button clicked (scale > 1)', () => {
    createComponent({}, { scale: 1.6 });
    return wrapper.vm.$nextTick().then(() => {
      getButton('reset').trigger('click');
      expect(wrapper.emitted('scale')).toEqual([[1]]);
    });
  });

  it('emits @scale event when "minus" button clicked (scale > 1)', () => {
    createComponent({}, { scale: 1.6 });

    return wrapper.vm.$nextTick().then(() => {
      getButton('minus').trigger('click');
      expect(wrapper.emitted('scale')).toEqual([[1.4]]);
    });
  });

  it('minus and reset buttons are disabled when scale === 1', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('minus and reset buttons are enabled when scale > 1', () => {
    createComponent({}, { scale: 1.2 });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('plus button is disabled when scale === 2', () => {
    createComponent({}, { scale: 2 });
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});

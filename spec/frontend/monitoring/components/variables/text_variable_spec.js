import { shallowMount } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import TextVariable from '~/monitoring/components/variables/text_variable.vue';

describe('Text variable component', () => {
  let wrapper;
  const propsData = {
    name: 'pod',
    label: 'Select pod',
    value: 'test-pod',
  };
  const createShallowWrapper = () => {
    wrapper = shallowMount(TextVariable, {
      propsData,
    });
  };

  const findInput = () => wrapper.find(GlFormInput);

  it('renders a text input when all props are passed', () => {
    createShallowWrapper();

    expect(findInput()).toExist();
  });

  it('always has a default value', () => {
    createShallowWrapper();

    return wrapper.vm.$nextTick(() => {
      expect(findInput().attributes('value')).toBe(propsData.value);
    });
  });

  it('triggers keyup enter', () => {
    createShallowWrapper();
    jest.spyOn(wrapper.vm, '$emit');

    findInput().element.value = 'prod-pod';
    findInput().trigger('input');
    findInput().trigger('keyup.enter');

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('onUpdate', 'pod', 'prod-pod');
    });
  });

  it('triggers blur enter', () => {
    createShallowWrapper();
    jest.spyOn(wrapper.vm, '$emit');

    findInput().element.value = 'canary-pod';
    findInput().trigger('input');
    findInput().trigger('blur');

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('onUpdate', 'pod', 'canary-pod');
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import CustomVariable from '~/monitoring/components/variables/custom_variable.vue';

describe('Custom variable component', () => {
  let wrapper;
  const propsData = {
    name: 'env',
    label: 'Select environment',
    value: 'Production',
    options: [{ text: 'Production', value: 'prod' }, { text: 'Canary', value: 'canary' }],
  };
  const createShallowWrapper = () => {
    wrapper = shallowMount(CustomVariable, {
      propsData,
    });
  };

  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);

  it('renders dropdown element when all necessary props are passed', () => {
    createShallowWrapper();

    expect(findDropdown()).toExist();
  });

  it('renders dropdown element with a text', () => {
    createShallowWrapper();

    expect(findDropdown().attributes('text')).toBe(propsData.value);
  });

  it('renders all the dropdown items', () => {
    createShallowWrapper();

    expect(findDropdownItems()).toHaveLength(propsData.options.length);
  });

  it('changing dropdown items triggers update', () => {
    createShallowWrapper();
    jest.spyOn(wrapper.vm, '$emit');

    findDropdownItems()
      .at(1)
      .vm.$emit('click');

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('onUpdate', 'env', 'canary');
    });
  });
});

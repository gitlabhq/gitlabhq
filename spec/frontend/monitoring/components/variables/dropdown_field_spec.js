import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DropdownField from '~/monitoring/components/variables/dropdown_field.vue';

describe('Custom variable component', () => {
  let wrapper;

  const defaultProps = {
    name: 'env',
    label: 'Select environment',
    value: 'Production',
    options: {
      values: [
        { text: 'Production', value: 'prod' },
        { text: 'Canary', value: 'canary' },
      ],
    },
  };

  const createShallowWrapper = (props) => {
    wrapper = shallowMount(DropdownField, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);

  it('renders dropdown element when all necessary props are passed', () => {
    createShallowWrapper();

    expect(findDropdown().exists()).toBe(true);
  });

  it('renders dropdown element with a text', () => {
    createShallowWrapper();

    expect(findDropdown().attributes('text')).toBe(defaultProps.value);
  });

  it('renders all the dropdown items', () => {
    createShallowWrapper();

    expect(findDropdownItems()).toHaveLength(defaultProps.options.values.length);
  });

  it('renders dropdown when values are missing', () => {
    createShallowWrapper({ options: {} });

    expect(findDropdown().exists()).toBe(true);
  });

  it('changing dropdown items triggers update', async () => {
    createShallowWrapper();
    jest.spyOn(wrapper.vm, '$emit');

    findDropdownItems().at(1).vm.$emit('click');

    await nextTick();
    expect(wrapper.vm.$emit).toHaveBeenCalledWith('input', 'canary');
  });
});

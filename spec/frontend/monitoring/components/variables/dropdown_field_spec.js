import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

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

  it('changing dropdown items triggers update', () => {
    createShallowWrapper();
    findDropdownItems().at(1).vm.$emit('click');

    expect(wrapper.emitted('input')).toEqual([['canary']]);
  });
});

import { GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';

describe('SingleChoice', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SingleChoiceSelector, {
      propsData: {
        ...props,
      },
    });
  };

  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  it('renders radio group', () => {
    createComponent();

    expect(findRadioGroup().exists()).toBe(true);
  });

  it('passes the checked prop to GlFormRadioGroup', () => {
    const checkedValue = 'test-option';
    createComponent({ checked: checkedValue });
    expect(findRadioGroup().attributes('checked')).toBe(checkedValue);
  });

  it('passes the name prop to GlFormRadioGroup', () => {
    const radioGroupName = 'test-name';
    createComponent({ checked: 'test-option', name: radioGroupName });
    expect(findRadioGroup().attributes('name')).toBe(radioGroupName);
  });
});

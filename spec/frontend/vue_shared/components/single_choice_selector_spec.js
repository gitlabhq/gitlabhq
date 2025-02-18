import { GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';

describe('SingleChoice', () => {
  let wrapper;

  const defaultPropsData = {
    checked: 'option',
  };

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(SingleChoiceSelector, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  }

  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);

  it('renders radio group', () => {
    createComponent();

    expect(findRadioGroup().exists()).toBe(true);
  });
});

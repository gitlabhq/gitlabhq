import { GlFormCheckboxGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';

describe('MultipleChoiceSelector', () => {
  let wrapper;

  const defaultPropsData = {
    selected: ['option'],
  };

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(MultipleChoiceSelector, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  }

  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);

  it('renders checkbox group', () => {
    createComponent();

    expect(findCheckboxGroup().exists()).toBe(true);
  });
});

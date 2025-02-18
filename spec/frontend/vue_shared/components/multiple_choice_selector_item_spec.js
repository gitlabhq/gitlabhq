import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MultipleChoiceSelectorItem from '~/vue_shared/components/multiple_choice_selector_item.vue';

describe('MultipleChoiceSelectorItem', () => {
  let wrapper;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(MultipleChoiceSelectorItem, {
      propsData: {
        ...propsData,
      },
    });
  }

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  it('renders checkbox', () => {
    createComponent();

    expect(findCheckbox().exists()).toBe(true);
  });

  it('renders title', () => {
    createComponent({ propsData: { title: 'Option title' } });

    expect(findCheckbox().text()).toContain('Option title');
  });

  it('renders description', () => {
    createComponent({ propsData: { description: 'Option description' } });

    expect(wrapper.text()).toContain('Option description');
  });

  it('renders disabled message', () => {
    createComponent({ propsData: { disabledMessage: 'Option disabled message', disabled: true } });

    expect(wrapper.text()).toContain('Option disabled message');
  });
});

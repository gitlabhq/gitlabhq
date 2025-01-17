import { GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

describe('SingleChoiceSelectorItem', () => {
  let wrapper;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMount(SingleChoiceSelectorItem, {
      propsData: {
        ...propsData,
      },
    });
  }

  const findRadio = () => wrapper.findComponent(GlFormRadio);

  it('renders radio', () => {
    createComponent();

    expect(findRadio().exists()).toBe(true);
  });

  it('renders title', () => {
    createComponent({ propsData: { title: 'Option title' } });

    expect(findRadio().text()).toContain('Option title');
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

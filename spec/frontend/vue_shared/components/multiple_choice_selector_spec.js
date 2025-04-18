import { GlFormCheckboxGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';

describe('MultipleChoiceSelector', () => {
  let wrapper;

  function createComponent({ props, ...options } = {}) {
    wrapper = shallowMount(MultipleChoiceSelector, {
      propsData: {
        ...props,
      },
      ...options,
    });
  }

  const findCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);

  it('renders checkbox group', () => {
    createComponent();

    expect(findCheckboxGroup().exists()).toBe(true);
  });

  it('checks options', () => {
    createComponent({
      props: {
        checked: ['my-option', 'my-option-2'],
      },
    });

    expect(findCheckboxGroup().attributes('checked')).toEqual('my-option,my-option-2');
  });

  it('emits checked options', () => {
    createComponent();

    findCheckboxGroup().vm.$emit('input', ['my-option-2']);

    expect(wrapper.emitted()).toEqual({
      input: [[['my-option-2']]],
    });
  });

  it('renders slot', () => {
    createComponent({
      slots: {
        default: 'content',
      },
    });

    expect(wrapper.html()).toContain('content');
  });
});

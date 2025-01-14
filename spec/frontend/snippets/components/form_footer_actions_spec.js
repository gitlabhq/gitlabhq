import { shallowMount } from '@vue/test-utils';
import FormFooterActions from '~/snippets/components/form_footer_actions.vue';

describe('Form Footer Actions', () => {
  let wrapper;

  function createComponent(slots = {}) {
    wrapper = shallowMount(FormFooterActions, {
      slots,
    });
  }

  it('renders content properly', () => {
    const defaultSlot = 'Foo';
    const prepend = 'Bar';
    const append = 'Abrakadabra';
    createComponent({
      default: defaultSlot,
      prepend,
      append,
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});

import { shallowMount } from '@vue/test-utils';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';

describe('Design Disclosure', () => {
  let wrapper;

  const findDisclosure = () => wrapper.find('.design-disclosure');

  function createComponent({ open = true } = {}) {
    wrapper = shallowMount(DesignDisclosure, {
      propsData: {
        open,
      },
    });
  }

  it('when open prop is true, it renders', () => {
    createComponent();

    expect(findDisclosure().exists()).toBe(true);
  });

  it('when open prop is false, it does not render', () => {
    createComponent({ open: false });

    expect(findDisclosure().exists()).toBe(false);
  });
});

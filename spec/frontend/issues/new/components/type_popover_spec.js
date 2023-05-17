import { shallowMount } from '@vue/test-utils';
import TypePopover from '~/issues/new/components/type_popover.vue';

describe('Issue type info popover', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(TypePopover);
  }

  it('renders', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});

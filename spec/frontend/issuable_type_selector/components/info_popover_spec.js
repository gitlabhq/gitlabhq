import { shallowMount } from '@vue/test-utils';
import InfoPopover from '~/issuable_type_selector/components/info_popover.vue';

describe('Issuable type info popover', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(InfoPopover);
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});

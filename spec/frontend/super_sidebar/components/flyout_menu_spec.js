import { shallowMount } from '@vue/test-utils';
import FlyoutMenu from '~/super_sidebar/components/flyout_menu.vue';

jest.mock('@floating-ui/dom');

describe('FlyoutMenu', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(FlyoutMenu, {
      propsData: {
        targetId: 'section-1',
        items: [],
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });
});

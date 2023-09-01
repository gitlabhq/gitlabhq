import { mountExtended } from 'helpers/vue_test_utils_helper';
import FlyoutMenu from '~/super_sidebar/components/flyout_menu.vue';

jest.mock('@floating-ui/dom');

describe('FlyoutMenu', () => {
  let wrapper;
  let dummySection;

  const createComponent = () => {
    dummySection = document.createElement('section');
    dummySection.addEventListener = jest.fn();

    dummySection.getBoundingClientRect = jest.fn();
    dummySection.getBoundingClientRect.mockReturnValue({ top: 0, bottom: 5, width: 10 });

    document.querySelector = jest.fn();
    document.querySelector.mockReturnValue(dummySection);

    wrapper = mountExtended(FlyoutMenu, {
      propsData: {
        targetId: 'section-1',
        items: [{ id: 1, title: 'item 1', link: 'https://example.com' }],
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

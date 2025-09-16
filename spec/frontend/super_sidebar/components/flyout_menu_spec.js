import { autoUpdate } from '@floating-ui/dom';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import FlyoutMenu, { FLYOUT_PADDING } from '~/super_sidebar/components/flyout_menu.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { setHTMLFixture } from 'helpers/fixtures';

jest.mock('@floating-ui/dom');

describe('FlyoutMenu', () => {
  const targetId = 'section-1';
  let wrapper;
  let autoUpdateCleanup;

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(FlyoutMenu, {
      attachTo: document.body,
      propsData: {
        targetId,
        items: [{ id: 1, title: 'item 1', link: 'https://example.com' }],
        title: 'Foo',
      },
      provide: {
        isIconOnly: false,
        ...provide,
      },
    });
  };

  const findHeader = () => wrapper.find('header');
  const findNavItem = () => wrapper.findComponent(NavItem);

  beforeEach(() => {
    autoUpdateCleanup = autoUpdate.mockReturnValue(jest.fn());
    setHTMLFixture(`
      <div id="${targetId}"></div>
      <div id="${targetId}-flyout"></div>
      <div id="super-sidebar"></div>
    `);
  });

  it('renders the component', () => {
    createComponent();
    expect(wrapper.exists()).toBe(true);
  });

  it('applies the correct padding', () => {
    createComponent();
    expect(wrapper.element.style.padding).toContain(`${FLYOUT_PADDING}px`);
    expect(wrapper.element.style.paddingLeft).toContain(`${FLYOUT_PADDING * 2}px`);
  });

  describe('header and separator', () => {
    describe('when isIconOnly is false', () => {
      it('does not render the header', () => {
        createComponent();
        expect(findHeader().exists()).toBe(false);
      });
    });

    describe('when isIconOnly is true', () => {
      it('renders the header', () => {
        createComponent({ isIconOnly: true });
        expect(findHeader().exists()).toBe(true);
        expect(findHeader().text()).toBe('Foo');
      });
    });
  });

  it('always provides isIconOnly as false to its child NavItems', () => {
    createComponent({ isIconOnly: true });
    expect(findNavItem().text()).toBe('item 1');
  });

  it('cleans up', () => {
    createComponent();
    wrapper.destroy();
    expect(autoUpdateCleanup).toHaveBeenCalled();
  });
});

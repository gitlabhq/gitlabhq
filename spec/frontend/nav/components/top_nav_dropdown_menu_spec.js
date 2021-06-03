import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TopNavDropdownMenu from '~/nav/components/top_nav_dropdown_menu.vue';
import TopNavMenuItem from '~/nav/components/top_nav_menu_item.vue';
import TopNavMenuSections from '~/nav/components/top_nav_menu_sections.vue';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import { TEST_NAV_DATA } from '../mock_data';

describe('~/nav/components/top_nav_dropdown_menu.vue', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TopNavDropdownMenu, {
      propsData: {
        primary: TEST_NAV_DATA.primary,
        secondary: TEST_NAV_DATA.secondary,
        views: TEST_NAV_DATA.views,
        ...props,
      },
      stubs: {
        // Stub the keep-alive-slots so we don't render frequent items which uses a store
        KeepAliveSlots: true,
      },
    });
  };

  const findMenuItems = () => wrapper.findAllComponents(TopNavMenuItem);
  const findMenuSections = () => wrapper.find(TopNavMenuSections);
  const findMenuSidebar = () => wrapper.find('[data-testid="menu-sidebar"]');
  const findMenuSubview = () => wrapper.findComponent(KeepAliveSlots);
  const hasFullWidthMenuSidebar = () => findMenuSidebar().classes('gl-w-full');

  const withActiveIndex = (menuItems, activeIndex) =>
    menuItems.map((x, idx) => ({
      ...x,
      active: idx === activeIndex,
    }));

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders menu sections', () => {
      expect(findMenuSections().props()).toEqual({
        sections: [
          { id: 'primary', menuItems: TEST_NAV_DATA.primary },
          { id: 'secondary', menuItems: TEST_NAV_DATA.secondary },
        ],
        withTopBorder: false,
      });
    });

    it('has full width menu sidebar', () => {
      expect(hasFullWidthMenuSidebar()).toBe(true);
    });

    it('renders hidden subview with no slot key', () => {
      const subview = findMenuSubview();

      expect(subview.isVisible()).toBe(false);
      expect(subview.props()).toEqual({ slotKey: '' });
    });
  });

  describe('with pre-initialized active view', () => {
    beforeEach(() => {
      // We opt for a small integration test, to make sure the event is handled correctly
      // as it would in prod.
      createComponent(
        {
          primary: withActiveIndex(TEST_NAV_DATA.primary, 1),
        },
        mount,
      );
    });

    it('renders menu sections', () => {
      expect(findMenuSections().props('sections')).toStrictEqual([
        { id: 'primary', menuItems: withActiveIndex(TEST_NAV_DATA.primary, 1) },
        { id: 'secondary', menuItems: TEST_NAV_DATA.secondary },
      ]);
    });

    it('does not have full width menu sidebar', () => {
      expect(hasFullWidthMenuSidebar()).toBe(false);
    });

    it('renders visible subview with slot key', () => {
      const subview = findMenuSubview();

      expect(subview.isVisible()).toBe(true);
      expect(subview.props('slotKey')).toBe(TEST_NAV_DATA.primary[1].view);
    });

    it('does not change view if non-view menu item is clicked', async () => {
      const secondaryLink = findMenuItems().at(TEST_NAV_DATA.primary.length);

      // Ensure this doesn't have a view
      expect(secondaryLink.props('menuItem').view).toBeUndefined();

      secondaryLink.vm.$emit('click');

      await nextTick();

      expect(findMenuSubview().props('slotKey')).toBe(TEST_NAV_DATA.primary[1].view);
    });

    describe('when menu item is clicked', () => {
      let primaryLink;

      beforeEach(async () => {
        primaryLink = findMenuItems().at(0);
        primaryLink.vm.$emit('click');
        await nextTick();
      });

      it('clicked on link with view', () => {
        expect(primaryLink.props('menuItem').view).toBeTruthy();
      });

      it('changes active view', () => {
        expect(findMenuSubview().props('slotKey')).toBe(TEST_NAV_DATA.primary[0].view);
      });

      it('changes active status on menu item', () => {
        expect(findMenuSections().props('sections')).toStrictEqual([
          {
            id: 'primary',
            menuItems: withActiveIndex(TEST_NAV_DATA.primary, 0),
          },
          {
            id: 'secondary',
            menuItems: withActiveIndex(TEST_NAV_DATA.secondary, -1),
          },
        ]);
      });
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TopNavDropdownMenu from '~/nav/components/top_nav_dropdown_menu.vue';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import { TEST_NAV_DATA } from '../mock_data';

const SECONDARY_GROUP_CLASSES = TopNavDropdownMenu.SECONDARY_GROUP_CLASS.split(' ');

describe('~/nav/components/top_nav_dropdown_menu.vue', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TopNavDropdownMenu, {
      propsData: {
        primary: TEST_NAV_DATA.primary,
        secondary: TEST_NAV_DATA.secondary,
        views: TEST_NAV_DATA.views,
        ...props,
      },
    });
  };

  const findMenuItems = (parent = wrapper) => parent.findAll('[data-testid="menu-item"]');
  const findMenuItemsModel = (parent = wrapper) =>
    findMenuItems(parent).wrappers.map((x) => ({
      menuItem: x.props('menuItem'),
      isActive: x.classes('active'),
    }));
  const findMenuItemGroups = () => wrapper.findAll('[data-testid="menu-item-group"]');
  const findMenuItemGroupsModel = () =>
    findMenuItemGroups().wrappers.map((x) => ({
      classes: x.classes(),
      items: findMenuItemsModel(x),
    }));
  const findMenuSidebar = () => wrapper.find('[data-testid="menu-sidebar"]');
  const findMenuSubview = () => wrapper.findComponent(KeepAliveSlots);
  const hasFullWidthMenuSidebar = () => findMenuSidebar().classes('gl-w-full');

  const createItemsGroupModelExpectation = ({
    primary = TEST_NAV_DATA.primary,
    secondary = TEST_NAV_DATA.secondary,
    activeIndex = -1,
  } = {}) => [
    {
      classes: [],
      items: primary.map((menuItem, index) => ({ isActive: index === activeIndex, menuItem })),
    },
    {
      classes: SECONDARY_GROUP_CLASSES,
      items: secondary.map((menuItem) => ({ isActive: false, menuItem })),
    },
  ];

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders menu item groups', () => {
      expect(findMenuItemGroupsModel()).toEqual(createItemsGroupModelExpectation());
    });

    it('has full width menu sidebar', () => {
      expect(hasFullWidthMenuSidebar()).toBe(true);
    });

    it('renders hidden subview with no slot key', () => {
      const subview = findMenuSubview();

      expect(subview.isVisible()).toBe(false);
      expect(subview.props()).toEqual({ slotKey: '' });
    });

    it('the first menu item in a group does not render margin top', () => {
      const actual = findMenuItems(findMenuItemGroups().at(0)).wrappers.map((x) =>
        x.classes('gl-mt-1'),
      );

      expect(actual).toEqual([false, ...TEST_NAV_DATA.primary.slice(1).fill(true)]);
    });
  });

  describe('with pre-initialized active view', () => {
    const primaryWithActive = [
      TEST_NAV_DATA.primary[0],
      {
        ...TEST_NAV_DATA.primary[1],
        active: true,
      },
      ...TEST_NAV_DATA.primary.slice(2),
    ];

    beforeEach(() => {
      createComponent({
        primary: primaryWithActive,
      });
    });

    it('renders menu item groups', () => {
      expect(findMenuItemGroupsModel()).toEqual(
        createItemsGroupModelExpectation({ primary: primaryWithActive, activeIndex: 1 }),
      );
    });

    it('does not have full width menu sidebar', () => {
      expect(hasFullWidthMenuSidebar()).toBe(false);
    });

    it('renders visible subview with slot key', () => {
      const subview = findMenuSubview();

      expect(subview.isVisible()).toBe(true);
      expect(subview.props('slotKey')).toBe(primaryWithActive[1].view);
    });

    it('does not change view if non-view menu item is clicked', async () => {
      const secondaryLink = findMenuItems().at(primaryWithActive.length);

      // Ensure this doesn't have a view
      expect(secondaryLink.props('menuItem').view).toBeUndefined();

      secondaryLink.vm.$emit('click');

      await nextTick();

      expect(findMenuSubview().props('slotKey')).toBe(primaryWithActive[1].view);
    });

    describe('when other view menu item is clicked', () => {
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
        expect(findMenuSubview().props('slotKey')).toBe(primaryWithActive[0].view);
      });

      it('changes active status on menu item', () => {
        expect(findMenuItemGroupsModel()).toStrictEqual(
          createItemsGroupModelExpectation({ primary: primaryWithActive, activeIndex: 0 }),
        );
      });
    });
  });
});

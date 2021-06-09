import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ResponsiveHome from '~/nav/components/responsive_home.vue';
import TopNavMenuItem from '~/nav/components/top_nav_menu_item.vue';
import TopNavMenuSections from '~/nav/components/top_nav_menu_sections.vue';
import TopNavNewDropdown from '~/nav/components/top_nav_new_dropdown.vue';
import { TEST_NAV_DATA } from '../mock_data';

const TEST_SEARCH_MENU_ITEM = {
  id: 'search',
  title: 'search',
  icon: 'search',
  href: '/search',
};

const TEST_NEW_DROPDOWN_VIEW_MODEL = {
  title: 'new',
  menu_sections: [],
};

describe('~/nav/components/responsive_home.vue', () => {
  let wrapper;
  let menuItemClickListener;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ResponsiveHome, {
      propsData: {
        navData: TEST_NAV_DATA,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
      listeners: {
        'menu-item-click': menuItemClickListener,
      },
    });
  };

  const findSearchMenuItem = () => wrapper.findComponent(TopNavMenuItem);
  const findNewDropdown = () => wrapper.findComponent(TopNavNewDropdown);
  const findMenuSections = () => wrapper.findComponent(TopNavMenuSections);

  beforeEach(() => {
    menuItemClickListener = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      desc                                | fn
      ${'does not show search menu item'} | ${findSearchMenuItem}
      ${'does not show new dropdown'}     | ${findNewDropdown}
    `('$desc', ({ fn }) => {
      expect(fn().exists()).toBe(false);
    });

    it('shows menu sections', () => {
      expect(findMenuSections().props('sections')).toEqual([
        { id: 'primary', menuItems: TEST_NAV_DATA.primary },
        { id: 'secondary', menuItems: TEST_NAV_DATA.secondary },
      ]);
    });

    it('emits when menu sections emits', () => {
      expect(menuItemClickListener).not.toHaveBeenCalled();

      findMenuSections().vm.$emit('menu-item-click', TEST_NAV_DATA.primary[0]);

      expect(menuItemClickListener).toHaveBeenCalledWith(TEST_NAV_DATA.primary[0]);
    });
  });

  describe('without secondary', () => {
    beforeEach(() => {
      createComponent({ navData: { ...TEST_NAV_DATA, secondary: null } });
    });

    it('shows menu sections', () => {
      expect(findMenuSections().props('sections')).toEqual([
        { id: 'primary', menuItems: TEST_NAV_DATA.primary },
      ]);
    });
  });

  describe('with search view', () => {
    beforeEach(() => {
      createComponent({
        navData: {
          ...TEST_NAV_DATA,
          views: { search: TEST_SEARCH_MENU_ITEM },
        },
      });
    });

    it('shows search menu item', () => {
      expect(findSearchMenuItem().props()).toEqual({
        menuItem: TEST_SEARCH_MENU_ITEM,
        iconOnly: true,
      });
    });

    it('shows tooltip for search', () => {
      const tooltip = getBinding(findSearchMenuItem().element, 'gl-tooltip');
      expect(tooltip.value).toEqual({ title: TEST_SEARCH_MENU_ITEM.title });
    });
  });

  describe('with new view', () => {
    beforeEach(() => {
      createComponent({
        navData: {
          ...TEST_NAV_DATA,
          views: { new: TEST_NEW_DROPDOWN_VIEW_MODEL },
        },
      });
    });

    it('shows new dropdown', () => {
      expect(findNewDropdown().props()).toEqual({
        viewModel: TEST_NEW_DROPDOWN_VIEW_MODEL,
      });
    });

    it('shows tooltip for new dropdown', () => {
      const tooltip = getBinding(findNewDropdown().element, 'gl-tooltip');
      expect(tooltip.value).toEqual({ title: TEST_NEW_DROPDOWN_VIEW_MODEL.title });
    });
  });
});

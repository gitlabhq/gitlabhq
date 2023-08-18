import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import { PANELS_WITH_PINS } from '~/super_sidebar/constants';
import { sidebarData } from '../mock_data';

const menuItems = [
  { id: 1, title: 'No subitems' },
  { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Pinned subitem' }] },
  { id: 3, title: 'Empty subitems array', items: [] },
  { id: 4, title: 'Also with subitems', items: [{ id: 41, title: 'Subitem' }] },
];

describe('Sidebar Menu', () => {
  let wrapper;
  let flyoutFlag = false;

  const createWrapper = (extraProps = {}) => {
    wrapper = shallowMountExtended(SidebarMenu, {
      provide: {
        glFeatures: { superSidebarFlyoutMenus: flyoutFlag },
      },
      propsData: {
        items: sidebarData.current_menu_items,
        isLoggedIn: sidebarData.is_logged_in,
        pinnedItemIds: sidebarData.pinned_items,
        panelType: sidebarData.panel_type,
        updatePinsUrl: sidebarData.update_pins_url,
        ...extraProps,
      },
    });
  };

  const findStaticItemsSection = () => wrapper.findByTestId('static-items-section');
  const findStaticItems = () => findStaticItemsSection().findAllComponents(NavItem);
  const findPinnedSection = () => wrapper.findComponent(PinnedSection);
  const findMainMenuSeparator = () => wrapper.findByTestId('main-menu-separator');
  const findNonStaticItemsSection = () => wrapper.findByTestId('non-static-items-section');
  const findNonStaticItems = () => findNonStaticItemsSection().findAllComponents(NavItem);
  const findNonStaticSectionItems = () =>
    findNonStaticItemsSection().findAllComponents(MenuSection);

  describe('Static section', () => {
    describe('when the sidebar supports pins', () => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType: PANELS_WITH_PINS[0],
        });
      });

      it('renders static items section', () => {
        expect(findStaticItemsSection().exists()).toBe(true);
        expect(findStaticItems().wrappers.map((w) => w.props('item').title)).toEqual([
          'No subitems',
          'Empty subitems array',
        ]);
      });
    });

    describe('when the sidebar does not support pins', () => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType: 'explore',
        });
      });

      it('does not render static items section', () => {
        expect(findStaticItemsSection().exists()).toBe(false);
      });
    });
  });

  describe('Pinned section', () => {
    it('is rendered in a project sidebar', () => {
      createWrapper({ panelType: 'project' });
      expect(findPinnedSection().exists()).toBe(true);
    });

    it('is rendered in a group sidebar', () => {
      createWrapper({ panelType: 'group' });
      expect(findPinnedSection().exists()).toBe(true);
    });

    it('is not rendered in other sidebars', () => {
      createWrapper({ panelType: 'your_work' });
      expect(findPinnedSection().exists()).toBe(false);
    });
  });

  describe('Non static items section', () => {
    describe('when the sidebar supports pins', () => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType: PANELS_WITH_PINS[0],
        });
      });

      it('keeps items that have subitems (aka "sections") as non-static', () => {
        expect(findNonStaticSectionItems().wrappers.map((w) => w.props('item').title)).toEqual([
          'With subitems',
          'Also with subitems',
        ]);
      });
    });

    describe('when the sidebar does not support pins', () => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType: 'explore',
        });
      });

      it('keeps all items as non-static', () => {
        expect(findNonStaticSectionItems().length + findNonStaticItems().length).toBe(
          menuItems.length,
        );
      });
    });

    describe('flyout menus', () => {
      describe('when feature is disabled', () => {
        beforeEach(() => {
          createWrapper({
            items: menuItems,
          });
        });

        it('does not add flyout menus to sections', () => {
          expect(findNonStaticSectionItems().wrappers.map((w) => w.props('hasFlyout'))).toEqual([
            false,
            false,
          ]);
        });
      });

      describe('when feature is enabled', () => {
        beforeEach(() => {
          flyoutFlag = true;
        });

        describe('when screen width is smaller than "md" breakpoint', () => {
          beforeEach(() => {
            jest.spyOn(GlBreakpointInstance, 'windowWidth').mockImplementation(() => {
              return 767;
            });
            createWrapper({
              items: menuItems,
            });
          });

          it('does not add flyout menus to sections', () => {
            expect(findNonStaticSectionItems().wrappers.map((w) => w.props('hasFlyout'))).toEqual([
              false,
              false,
            ]);
          });
        });

        describe('when screen width is equal or larger than "md" breakpoint', () => {
          beforeEach(() => {
            jest.spyOn(GlBreakpointInstance, 'windowWidth').mockImplementation(() => {
              return 768;
            });
            createWrapper({
              items: menuItems,
            });
          });

          it('adds flyout menus to sections', () => {
            expect(findNonStaticSectionItems().wrappers.map((w) => w.props('hasFlyout'))).toEqual([
              true,
              true,
            ]);
          });
        });
      });
    });
  });

  describe('Separators', () => {
    it('should add the separator above pinned section', () => {
      createWrapper({
        items: menuItems,
        panelType: 'project',
      });
      expect(findPinnedSection().props('separated')).toBe(true);
    });

    it('should add the separator above main menu items when there is a pinned section', () => {
      createWrapper({
        items: menuItems,
        panelType: PANELS_WITH_PINS[0],
      });
      expect(findMainMenuSeparator().exists()).toBe(true);
    });

    it('should NOT add the separator above main menu items when there is no pinned section', () => {
      createWrapper({
        items: menuItems,
        panelType: 'explore',
      });
      expect(findMainMenuSeparator().exists()).toBe(false);
    });
  });

  describe('ARIA attributes', () => {
    it('adds aria-label attribute to nav element', () => {
      createWrapper();
      expect(wrapper.find('nav').attributes('aria-label')).toBe('Main navigation');
    });
  });
});

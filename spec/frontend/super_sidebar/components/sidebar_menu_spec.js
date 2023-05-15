import { mountExtended } from 'helpers/vue_test_utils_helper';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import { PANELS_WITH_PINS } from '~/super_sidebar/constants';
import { sidebarData } from '../mock_data';

describe('SidebarMenu component', () => {
  let wrapper;

  const createWrapper = (mockData) => {
    wrapper = mountExtended(SidebarMenu, {
      propsData: {
        items: mockData.current_menu_items,
        pinnedItemIds: mockData.pinned_items,
        panelType: mockData.panel_type,
        updatePinsUrl: mockData.update_pins_url,
      },
    });
  };

  describe('computed', () => {
    const menuItems = [
      { id: 1, title: 'No subitems' },
      { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Pinned subitem' }] },
      { id: 3, title: 'Empty subitems array', items: [] },
      { id: 4, title: 'Also with subitems', items: [{ id: 41, title: 'Subitem' }] },
    ];

    describe('supportsPins', () => {
      it('is true for the project sidebar', () => {
        createWrapper({ ...sidebarData, panel_type: 'project' });
        expect(wrapper.vm.supportsPins).toBe(true);
      });

      it('is true for the group sidebar', () => {
        createWrapper({ ...sidebarData, panel_type: 'group' });
        expect(wrapper.vm.supportsPins).toBe(true);
      });

      it('is false for any other sidebar', () => {
        createWrapper({ ...sidebarData, panel_type: 'your_work' });
        expect(wrapper.vm.supportsPins).toEqual(false);
      });
    });

    describe('flatPinnableItems', () => {
      it('returns all subitems in a flat array', () => {
        createWrapper({ ...sidebarData, current_menu_items: menuItems });
        expect(wrapper.vm.flatPinnableItems).toEqual([
          { id: 21, title: 'Pinned subitem' },
          { id: 41, title: 'Subitem' },
        ]);
      });
    });

    describe('staticItems', () => {
      describe('when the sidebar supports pins', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            panel_type: PANELS_WITH_PINS[0],
          });
        });

        it('makes everything that has no subitems a static item', () => {
          expect(wrapper.vm.staticItems.map((i) => i.title)).toEqual([
            'No subitems',
            'Empty subitems array',
          ]);
        });
      });

      describe('when the sidebar does not support pins', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            panel_type: 'explore',
          });
        });

        it('returns an empty array', () => {
          expect(wrapper.vm.staticItems.map((i) => i.title)).toEqual([]);
        });
      });
    });

    describe('nonStaticItems', () => {
      describe('when the sidebar supports pins', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            panel_type: PANELS_WITH_PINS[0],
          });
        });

        it('keeps items that have subitems (aka "sections") as non-static', () => {
          expect(wrapper.vm.nonStaticItems.map((i) => i.title)).toEqual([
            'With subitems',
            'Also with subitems',
          ]);
        });
      });

      describe('when the sidebar does not support pins', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            panel_type: 'explore',
          });
        });

        it('keeps all items as non-static', () => {
          expect(wrapper.vm.nonStaticItems).toEqual(menuItems);
        });
      });
    });

    describe('pinnedItems', () => {
      describe('when user has no pinned item ids stored', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            pinned_items: [],
          });
        });

        it('returns an empty array', () => {
          expect(wrapper.vm.pinnedItems).toEqual([]);
        });
      });

      describe('when user has some pinned item ids stored', () => {
        beforeEach(() => {
          createWrapper({
            ...sidebarData,
            current_menu_items: menuItems,
            pinned_items: [21],
          });
        });

        it('returns the items matching the pinned ids', () => {
          expect(wrapper.vm.pinnedItems).toEqual([{ id: 21, title: 'Pinned subitem' }]);
        });
      });
    });
  });
});

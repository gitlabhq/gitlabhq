import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import superSidebarDataQuery from '~/super_sidebar/graphql/queries/super_sidebar.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import { PANELS_WITH_PINS, PINNED_NAV_STORAGE_KEY } from '~/super_sidebar/constants';
import { sidebarData, sidebarDataCountResponse } from 'ee_else_ce_jest/super_sidebar/mock_data';

const menuItems = [
  { id: 1, title: 'No subitems' },
  { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Pinned subitem' }] },
  { id: 3, title: 'Empty subitems array', items: [] },
  { id: 4, title: 'Also with subitems', items: [{ id: 41, title: 'Subitem' }] },
];

Vue.use(VueApollo);

describe('Sidebar Menu', () => {
  let wrapper;
  let handler;

  const createWrapper = ({ queryHandler = handler, provide = {}, ...extraProps }) => {
    wrapper = shallowMountExtended(SidebarMenu, {
      apolloProvider: createMockApollo([[superSidebarDataQuery, queryHandler]]),
      propsData: {
        items: sidebarData.current_menu_items,
        isLoggedIn: sidebarData.is_logged_in,
        pinnedItemIds: sidebarData.pinned_items,
        panelType: sidebarData.panel_type,
        updatePinsUrl: sidebarData.update_pins_url,
        ...extraProps,
      },
      provide: {
        currentPath: 'group',
        ...provide,
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

  describe('Separators', () => {
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

  describe('Detect if pinned nav item was used', () => {
    describe('when sessionStorage is "true"', () => {
      beforeEach(() => {
        window.sessionStorage.setItem(PINNED_NAV_STORAGE_KEY, 'true');
        createWrapper({ panelType: 'project' });
      });

      it('sets prop for pinned section to true', () => {
        expect(findPinnedSection().props('wasPinnedNav')).toBe(true);
      });
    });

    describe('when sessionStorage is null', () => {
      beforeEach(() => {
        window.sessionStorage.setItem(PINNED_NAV_STORAGE_KEY, null);
        createWrapper({ panelType: 'project' });
      });

      it('sets prop for pinned section to false', () => {
        expect(findPinnedSection().props('wasPinnedNav')).toBe(false);
      });
    });
  });

  describe('Fetching async nav item pill count', () => {
    handler = jest.fn().mockResolvedValue(
      sidebarDataCountResponse({
        openIssuesCount: 8,
        openMergeRequestsCount: 2,
      }),
    );

    it('when there is no `currentPath` prop, the query is not called', async () => {
      createWrapper({
        provide: { currentPath: null },
      });
      await waitForPromises();

      expect(handler).not.toHaveBeenCalled();
    });

    it('when there is a `currentPath` prop, the query is called', async () => {
      createWrapper({
        provide: {
          currentPath: 'group',
        },
      });
      await waitForPromises();

      expect(handler).toHaveBeenCalled();
    });
  });

  describe('Child components receive correct asyncCount prop', () => {
    const emptyData = {
      data: null,
    };
    const emptyNamespace = {
      data: {
        namespace: null,
      },
    };
    const emptySidebar = {
      data: {
        namespace: {
          id: 'gid://gitlab/Project/11',
          sidebar: null,
          __typename: 'Namespace',
        },
      },
    };

    describe('When the query is successful', () => {
      it.each`
        component               | panelType              | property       | response          | componentAsyncProp
        ${'static NavItem'}     | ${PANELS_WITH_PINS[0]} | ${'data'}      | ${emptyData}      | ${findStaticItems}
        ${'static NavItem'}     | ${PANELS_WITH_PINS[0]} | ${'namespace'} | ${emptyNamespace} | ${findStaticItems}
        ${'static NavItem'}     | ${PANELS_WITH_PINS[0]} | ${'sidebar'}   | ${emptySidebar}   | ${findStaticItems}
        ${'non-static NavItem'} | ${'explore'}           | ${'data'}      | ${emptyData}      | ${findNonStaticItems}
        ${'non-static NavItem'} | ${'explore'}           | ${'namespace'} | ${emptyNamespace} | ${findNonStaticItems}
        ${'non-static NavItem'} | ${'explore'}           | ${'sidebar'}   | ${emptySidebar}   | ${findNonStaticItems}
        ${'MenuSection'}        | ${PANELS_WITH_PINS[0]} | ${'data'}      | ${emptyData}      | ${findNonStaticSectionItems}
        ${'MenuSection'}        | ${PANELS_WITH_PINS[0]} | ${'namespace'} | ${emptyNamespace} | ${findNonStaticSectionItems}
        ${'MenuSection'}        | ${PANELS_WITH_PINS[0]} | ${'sidebar'}   | ${emptySidebar}   | ${findNonStaticSectionItems}
      `(
        'asyncCount prop returns an empty object when `$property` is undefined for `$component`',
        async ({ response, panelType, componentAsyncProp }) => {
          handler = jest.fn().mockResolvedValue(response);

          createWrapper({
            items: menuItems,
            panelType,
            handler,
            provide: {
              currentPath: 'group',
            },
          });

          await waitForPromises();

          expect(handler).toHaveBeenCalled();
          expect(componentAsyncProp().wrappers.map((w) => w.props('asyncCount'))[0]).toEqual({});
        },
      );

      it.each`
        component          | panelType    | property       | response
        ${'PinnedSection'} | ${'project'} | ${'data'}      | ${emptyData}
        ${'PinnedSection'} | ${'project'} | ${'namespace'} | ${emptyNamespace}
        ${'PinnedSection'} | ${'project'} | ${'sidebar'}   | ${emptySidebar}
      `(
        'asyncCount prop returns an empty object when `$property` is undefined for `$component`',
        async ({ response, panelType }) => {
          handler = jest.fn().mockResolvedValue(response);

          createWrapper({
            items: menuItems,
            panelType,
            handler,
            provide: {
              currentPath: 'group',
            },
          });

          await waitForPromises();

          expect(handler).toHaveBeenCalled();
          expect(findPinnedSection().props('asyncCount')).toEqual({});
        },
      );

      it.each`
        component               | panelType              | componentAsyncProp
        ${'static NavItem'}     | ${PANELS_WITH_PINS[0]} | ${findStaticItems}
        ${'non-static NavItem'} | ${'explore'}           | ${findNonStaticItems}
        ${'MenuSection'}        | ${PANELS_WITH_PINS[0]} | ${findNonStaticSectionItems}
      `(
        'asyncCount prop returns the sidebar object for `$component` when it exists',
        async ({ panelType, componentAsyncProp }) => {
          const asyncCountData = {
            openIssuesCount: 8,
            openMergeRequestsCount: 2,
            __typename: 'NamespaceSidebar',
          };

          handler = jest.fn().mockResolvedValue(
            sidebarDataCountResponse({
              openIssuesCount: 8,
              openMergeRequestsCount: 2,
            }),
          );

          createWrapper({
            items: menuItems,
            panelType,
            provide: {
              currentPath: 'group',
            },
          });

          await waitForPromises();

          expect(handler).toHaveBeenCalled();
          expect(componentAsyncProp().wrappers.map((w) => w.props('asyncCount'))[0]).toMatchObject(
            asyncCountData,
          );
        },
      );

      it('asyncCount prop returns the sidebar object for PinnedSection when it exists', async () => {
        const asyncCountData = {
          openIssuesCount: 8,
          openMergeRequestsCount: 2,
          __typename: 'NamespaceSidebar',
        };

        handler = jest.fn().mockResolvedValue(
          sidebarDataCountResponse({
            openIssuesCount: 8,
            openMergeRequestsCount: 2,
          }),
        );

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: {
            currentPath: 'group',
          },
        });

        await waitForPromises();

        expect(handler).toHaveBeenCalled();
        expect(findPinnedSection().props('asyncCount')).toMatchObject(asyncCountData);
      });
    });

    describe('When the query is unsuccessful', () => {
      beforeEach(() => {
        handler = jest.fn().mockRejectedValue();
      });

      it.each`
        component               | panelType              | componentAsyncProp
        ${'static NavItem'}     | ${PANELS_WITH_PINS[0]} | ${findStaticItems}
        ${'non-static NavItem'} | ${'explore'}           | ${findNonStaticItems}
        ${'MenuSection'}        | ${PANELS_WITH_PINS[0]} | ${findNonStaticSectionItems}
      `(
        'asyncCount prop returns an empty object for `$component` when the query fails',
        async ({ panelType, componentAsyncProp }) => {
          createWrapper({
            items: menuItems,
            panelType,
            handler,
            provide: {
              currentPath: 'group',
            },
          });

          await waitForPromises();

          expect(handler).toHaveBeenCalled();
          expect(componentAsyncProp().wrappers.map((w) => w.props('asyncCount'))[0]).toEqual({});
        },
      );

      it('asyncCount prop returns an empty object for PinnedSection when the query fails', async () => {
        createWrapper({
          items: menuItems,
          panelType: 'project',
          handler,
          provide: {
            currentPath: 'group',
          },
        });

        await waitForPromises();

        expect(handler).toHaveBeenCalled();
        expect(findPinnedSection().props('asyncCount')).toEqual({});
      });
    });
  });
});

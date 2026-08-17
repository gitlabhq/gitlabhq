import Vue from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import { Portal } from 'portal-vue';
import { createWrapper as createRootWrapper } from '@vue/test-utils';
// eslint-disable-next-line no-restricted-syntax -- test mocks viewport breakpoints used by the source component
import { GlBreakpointInstance } from '@gitlab/ui/src/utils';
import superSidebarDataQuery from '~/super_sidebar/graphql/queries/super_sidebar.query.graphql';
import dismissUserCalloutMutation from '~/graphql_shared/mutations/dismiss_user_callout.mutation.graphql';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import PinnedSection from '~/super_sidebar/components/pinned_section.vue';
import { Mousetrap } from '~/lib/mousetrap';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { MODAL_ID } from '~/super_sidebar/components/feature_library/constants';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import {
  HIDDEN_NAV_ITEM_CLASS,
  PANELS_WITH_PINS,
  PINNED_NAV_STORAGE_KEY,
  MAX_OPEN_WORK_ITEMS_COUNT,
} from '~/super_sidebar/constants';
import { sidebarData, sidebarDataCountResponse } from 'ee_else_ce_jest/super_sidebar/mock_data';
import { userCounts } from '~/super_sidebar/user_counts_manager';

const menuItems = [
  { id: 1, title: 'No subitems' },
  { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Pinned subitem' }] },
  { id: 3, title: 'Empty subitems array', items: [] },
  { id: 4, title: 'Also with subitems', items: [{ id: 41, title: 'Subitem' }] },
  {
    id: 'settings_menu',
    title: 'Settings',
    items: [{ id: 'settings_general', title: 'General' }],
  },
];

Vue.use(VueApollo);

describe('Sidebar Menu', () => {
  let wrapper;
  let handler;

  const createWrapper = ({ queryHandler = handler, provide = {}, attachTo, ...extraProps }) => {
    wrapper = shallowMountExtended(SidebarMenu, {
      attachTo,
      apolloProvider: createMockApollo([[superSidebarDataQuery, queryHandler]]),
      propsData: {
        items: sidebarData.current_menu_items,
        isLoggedIn: sidebarData.is_logged_in,
        pinnedItemIds: sidebarData.pinned_items,
        panelType: sidebarData.panel_type,
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
  const findSettingsPortal = () => wrapper.findComponent(Portal);

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

    describe('interactivity (supportsPins prop)', () => {
      it('is interactive when logged in on a pin-supporting panel', () => {
        createWrapper({ panelType: 'project', isLoggedIn: true });
        expect(findPinnedSection().props('supportsPins')).toBe(true);
      });

      it('renders but is read-only for logged-out users', () => {
        createWrapper({ panelType: 'project', isLoggedIn: false });
        expect(findPinnedSection().exists()).toBe(true);
        expect(findPinnedSection().props('supportsPins')).toBe(false);
      });

      it('is not rendered on non-pin panels even for logged-out users', () => {
        createWrapper({ panelType: 'your_work', isLoggedIn: false });
        expect(findPinnedSection().exists()).toBe(false);
      });
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
          'Settings',
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
            true,
          ]);
        });
      });
    });

    describe('settings section', () => {
      const findSettingsSection = () =>
        findNonStaticSectionItems().wrappers.find((w) => w.props('item').id === 'settings_menu');

      beforeEach(() => {
        jest.spyOn(GlBreakpointInstance, 'windowWidth').mockImplementation(() => 768);
      });

      describe('when hideUnpinnedSidebarItems is disabled', () => {
        beforeEach(() => {
          createWrapper({ items: menuItems, panelType: 'project' });
        });

        it('renders the settings section in place with a flyout, not as a disclosure', () => {
          const settingsSection = findSettingsSection();

          expect(settingsSection.props('disclosure')).toBe(false);
          expect(settingsSection.props('hasFlyout')).toBe(true);
        });
      });

      describe('when hideUnpinnedSidebarItems is enabled', () => {
        let axiosMock;

        beforeEach(() => {
          axiosMock = new MockAdapter(axios);
          axiosMock.onPut().reply(HTTP_STATUS_OK, []);

          createWrapper({
            items: menuItems,
            panelType: 'project',
            isLoggedIn: true,
            provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
          });
        });

        afterEach(() => {
          axiosMock.restore();
        });

        it('renders the settings section as a disclosure without a flyout', () => {
          const settingsSection = findSettingsSection();

          expect(settingsSection.props('disclosure')).toBe(true);
          expect(settingsSection.props('hasFlyout')).toBe(false);
        });

        it('passes the pin context to the portalled section', () => {
          const settingsSection = findSettingsSection();

          expect(settingsSection.props('pinContext')).toMatchObject({
            panelSupportsPins: true,
            panelType: 'project',
          });
        });

        it('relays pin-add from the settings section to persist the pin', async () => {
          findSettingsSection().vm.$emit('pin-add', 'settings_general', 'General');
          await waitForPromises();

          expect(JSON.parse(axiosMock.history.put[0].data).menu_item_ids).toContain(
            'settings_general',
          );
        });

        it('relays pin-remove from the settings section to persist the unpin', async () => {
          findSettingsSection().vm.$emit('pin-add', 'settings_general', 'General');
          findSettingsSection().vm.$emit('pin-remove', 'settings_general', 'General');
          await waitForPromises();

          const lastPut = axiosMock.history.put.at(-1);
          expect(JSON.parse(lastPut.data).menu_item_ids).not.toContain('settings_general');
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
    handler = jest.fn().mockResolvedValue(sidebarDataCountResponse());

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

      it('provides userCounts as async counts when panel is "Your work"', async () => {
        Object.assign(userCounts, {
          todos: 112,
          assigned_issues: 0,
          assigned_merge_requests: 3,
          review_requested_merge_requests: 4,
          last_update: Date.now(),
        });

        createWrapper({
          items: menuItems,
          panelType: 'your_work',
        });

        await waitForPromises();

        expect(findNonStaticItems().wrappers.map((w) => w.props('asyncCount'))[0]).toMatchObject({
          assigned_issues: null,
          assigned_merge_requests: 3,
          last_update: 1593993600000,
          review_requested_merge_requests: 4,
          todos: 112,
          total_merge_requests: 7,
        });
      });

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
          handler = jest.fn().mockResolvedValue(sidebarDataCountResponse());

          createWrapper({
            items: menuItems,
            panelType,
            provide: {
              currentPath: 'group',
            },
          });

          await waitForPromises();

          expect(handler).toHaveBeenCalled();
          expect(componentAsyncProp().wrappers.map((w) => w.props('asyncCount'))[0]).toMatchObject({
            openIssuesCount: '8',
            openMergeRequestsCount: '236.5k',
          });
        },
      );

      it('asyncCount prop returns the sidebar object for PinnedSection when it exists', async () => {
        handler = jest.fn().mockResolvedValue(sidebarDataCountResponse());

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: {
            currentPath: 'group',
          },
        });

        await waitForPromises();

        expect(handler).toHaveBeenCalled();
        expect(findPinnedSection().props('asyncCount')).toMatchObject({
          openIssuesCount: '8',
          openMergeRequestsCount: '236.5k',
        });
      });

      it('formats openWorkItemsCount as "10k+" when it equals the max limit', async () => {
        handler = jest
          .fn()
          .mockResolvedValue(
            sidebarDataCountResponse({ openWorkItemsCount: MAX_OPEN_WORK_ITEMS_COUNT }),
          );

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: { currentPath: 'group' },
        });

        await waitForPromises();

        expect(findPinnedSection().props('asyncCount')).toMatchObject({
          openWorkItemsCount: '10k+',
        });
      });

      it('formats openWorkItemsCount normally when below the max limit', async () => {
        handler = jest
          .fn()
          .mockResolvedValue(sidebarDataCountResponse({ openWorkItemsCount: 9999 }));

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: { currentPath: 'group' },
        });

        await waitForPromises();

        expect(findPinnedSection().props('asyncCount')).toMatchObject({
          openWorkItemsCount: '10k',
        });
      });

      it('does not append "+" to openIssuesCount even when it equals the max limit', async () => {
        handler = jest
          .fn()
          .mockResolvedValue(
            sidebarDataCountResponse({ openIssuesCount: MAX_OPEN_WORK_ITEMS_COUNT }),
          );

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: { currentPath: 'group' },
        });

        await waitForPromises();

        expect(findPinnedSection().props('asyncCount')).toMatchObject({
          openIssuesCount: '10k',
        });
      });

      it('includes openWorkItemsCount in asyncCount', async () => {
        handler = jest.fn().mockResolvedValue(sidebarDataCountResponse({ openWorkItemsCount: 5 }));

        createWrapper({
          items: menuItems,
          panelType: 'project',
          provide: {
            currentPath: 'group',
          },
        });

        await waitForPromises();

        expect(findPinnedSection().props('asyncCount')).toMatchObject({
          openWorkItemsCount: '5',
        });
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

  describe('Feature Library modal', () => {
    const findFeatureLibraryModal = () => wrapper.findComponent({ name: 'FeatureLibraryModal' });
    const findTrigger = () => wrapper.findComponentByTestId('feature-library-trigger');

    describe('when the panel supports pins', () => {
      beforeEach(() => {
        createWrapper({
          panelType: PANELS_WITH_PINS[0],
        });
      });

      it('renders the trigger button with the expected label', () => {
        expect(findTrigger().exists()).toBe(true);
        expect(findTrigger().text()).toBe('More features');
      });

      it('renders the applications icon on the trigger', () => {
        expect(findTrigger().props('icon')).toBe('applications');
      });

      it('does not apply the shimmer class when showFeatureLibraryShimmer is false', () => {
        expect(findTrigger().classes()).not.toContain('feature-library-shimmer');
      });

      it('renders the modal', () => {
        expect(findFeatureLibraryModal().exists()).toBe(true);
      });

      it('passes supportsPins=true so pin actions are interactive', () => {
        expect(findFeatureLibraryModal().props('supportsPins')).toBe(true);
      });

      it('passes the section nav items (those with subitems) to the modal', () => {
        createWrapper({
          items: menuItems,
          panelType: PANELS_WITH_PINS[0],
        });
        expect(
          findFeatureLibraryModal()
            .props('sections')
            .map((s) => s.id),
        ).toEqual([2, 4, 'settings_menu']);
      });
    });

    describe('when the sidebar is collapsed to icon-only', () => {
      beforeEach(() => {
        createWrapper({
          panelType: PANELS_WITH_PINS[0],
          provide: { isIconOnly: true },
        });
      });

      it('hides the trigger label so only the icon remains', () => {
        expect(findTrigger().props('isIconOnly')).toBe(true);
      });
    });

    describe('when logged out on a pin-supporting panel', () => {
      beforeEach(() => {
        createWrapper({
          panelType: PANELS_WITH_PINS[0],
          isLoggedIn: false,
        });
      });

      it('renders the modal', () => {
        expect(findFeatureLibraryModal().exists()).toBe(true);
      });

      it('passes supportsPins=false so pin actions are hidden', () => {
        expect(findFeatureLibraryModal().props('supportsPins')).toBe(false);
      });
    });

    describe('when the panel does not support pins', () => {
      beforeEach(() => {
        createWrapper({
          panelType: 'your_work',
          isLoggedIn: true,
        });
      });

      it('does not render the trigger button (panel must support pins)', () => {
        expect(findTrigger().exists()).toBe(false);
      });

      it('does not render the modal', () => {
        expect(findFeatureLibraryModal().exists()).toBe(false);
      });
    });

    describe('keyboard shortcut', () => {
      const emittedShowModal = () => createRootWrapper(wrapper.vm.$root).emitted(BV_SHOW_MODAL);

      describe('when the modal is available', () => {
        beforeEach(() => {
          createWrapper({
            panelType: PANELS_WITH_PINS[0],
          });
        });

        it('opens the modal on \\', () => {
          Mousetrap.trigger('\\');

          expect(emittedShowModal()[0]).toContain(MODAL_ID);
        });

        it('returns false from the handler to prevent the default browser behavior', () => {
          expect(wrapper.vm.openFeatureLibrary()).toBe(false);
        });
      });

      describe('when the component is destroyed', () => {
        beforeEach(() => {
          createWrapper({
            panelType: PANELS_WITH_PINS[0],
          });
          jest.spyOn(Mousetrap, 'unbind');

          wrapper.destroy();
        });

        it('unbinds the shortcut', () => {
          expect(Mousetrap.unbind).toHaveBeenCalledWith(['\\']);
        });
      });

      describe('when the panel does not support pins', () => {
        beforeEach(() => {
          createWrapper({
            panelType: 'your_work',
          });
        });

        it('does not bind the shortcut', () => {
          Mousetrap.trigger('\\');

          expect(emittedShowModal()).toBeUndefined();
        });
      });

      describe('when in pinned-only mode', () => {
        beforeEach(() => {
          createWrapper({
            panelType: PANELS_WITH_PINS[0],
            provide: {
              glFeatures: { hideUnpinnedSidebarItems: true },
            },
          });
        });

        it('binds the shortcut', () => {
          Mousetrap.trigger('\\');

          expect(emittedShowModal()[0]).toContain(MODAL_ID);
        });
      });

      describe('when on the organization panel', () => {
        beforeEach(() => {
          createWrapper({
            panelType: 'organization',
          });
        });

        it('does not bind the shortcut', () => {
          Mousetrap.trigger('\\');

          expect(emittedShowModal()).toBeUndefined();
        });
      });
    });

    describe('onModalPinToggle', () => {
      beforeEach(() => {
        createWrapper({
          panelType: PANELS_WITH_PINS[0],
        });
      });

      // Uses an id absent from MOCK_CATALOG to prove the title comes from the
      // event payload, not a catalog lookup — the forward-compatible path once
      // server-driven items (not in the mock) replace the fixture.
      it('calls createPin with the title from the event when nextState is true', () => {
        const spy = jest.spyOn(wrapper.vm, 'createPin').mockImplementation(() => {});
        wrapper.vm.onModalPinToggle('server_only_item', true, 'Server Feature');
        expect(spy).toHaveBeenCalledWith('server_only_item', 'Server Feature');
      });

      it('calls destroyPin with the title from the event when nextState is false', () => {
        const spy = jest.spyOn(wrapper.vm, 'destroyPin').mockImplementation(() => {});
        wrapper.vm.onModalPinToggle('server_only_item', false, 'Server Feature');
        expect(spy).toHaveBeenCalledWith('server_only_item', 'Server Feature');
      });

      it('falls back to itemId when no title is provided', () => {
        const spy = jest.spyOn(wrapper.vm, 'createPin').mockImplementation(() => {});
        wrapper.vm.onModalPinToggle('some_item', true);
        expect(spy).toHaveBeenCalledWith('some_item', 'some_item');
      });
    });

    describe('shimmer', () => {
      let dismissHandler;

      const createShimmerWrapper = ({ showFeatureLibraryShimmer = true } = {}) => {
        dismissHandler = jest.fn().mockResolvedValue({
          data: {
            userCalloutCreate: {
              errors: [],
              userCallout: {
                dismissedAt: '2020-01-01T00:00:00Z',
                featureName: 'feature_library_shimmer_seen',
              },
            },
          },
        });

        wrapper = shallowMountExtended(SidebarMenu, {
          apolloProvider: createMockApollo([
            [superSidebarDataQuery, handler],
            [dismissUserCalloutMutation, dismissHandler],
          ]),
          propsData: {
            items: sidebarData.current_menu_items,
            isLoggedIn: sidebarData.is_logged_in,
            pinnedItemIds: sidebarData.pinned_items,
            panelType: PANELS_WITH_PINS[0],
            showFeatureLibraryShimmer,
          },
          provide: {
            currentPath: 'group',
          },
        });
      };

      it('applies the shimmer class when the shimmer should be shown', () => {
        createShimmerWrapper({ showFeatureLibraryShimmer: true });

        expect(findTrigger().classes()).toContain('feature-library-shimmer');
      });

      describe('when the trigger is clicked', () => {
        beforeEach(async () => {
          createShimmerWrapper({ showFeatureLibraryShimmer: true });
          findTrigger().vm.$emit('click');
          await waitForPromises();
        });

        it('dismisses the callout', () => {
          expect(dismissHandler).toHaveBeenCalledWith({
            input: { featureName: 'feature_library_shimmer_seen' },
          });
        });

        it('removes the shimmer class', () => {
          expect(findTrigger().classes()).not.toContain('feature-library-shimmer');
        });
      });

      describe('when the keyboard shortcut is used', () => {
        beforeEach(async () => {
          createShimmerWrapper({ showFeatureLibraryShimmer: true });
          Mousetrap.trigger('\\');
          await waitForPromises();
        });

        it('dismisses the callout', () => {
          expect(dismissHandler).toHaveBeenCalledWith({
            input: { featureName: 'feature_library_shimmer_seen' },
          });
        });

        it('removes the shimmer class', () => {
          expect(findTrigger().classes()).not.toContain('feature-library-shimmer');
        });
      });

      it('only dismisses the callout once across multiple clicks', async () => {
        createShimmerWrapper({ showFeatureLibraryShimmer: true });

        findTrigger().vm.$emit('click');
        findTrigger().vm.$emit('click');
        await waitForPromises();

        expect(dismissHandler).toHaveBeenCalledTimes(1);
      });

      it('does not dismiss the callout when the shimmer is already hidden', async () => {
        createShimmerWrapper({ showFeatureLibraryShimmer: false });

        findTrigger().vm.$emit('click');
        await waitForPromises();

        expect(dismissHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe('when hide_unpinned_sidebar_items feature flag is enabled', () => {
    describe.each`
      panelType
      ${'project'}
      ${'group'}
    `('with panelType=$panelType', ({ panelType }) => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType,
          provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
        });
      });

      it('renders only the settings section in the non-static items', () => {
        const sections = findNonStaticSectionItems();
        expect(sections).toHaveLength(1);
        expect(sections.at(0).props('item').id).toBe('settings_menu');
      });

      it('renders the settings section as a disclosure', () => {
        expect(findNonStaticSectionItems().at(0).props('disclosure')).toBe(true);
      });

      it('portals the settings section to the disclosure target', () => {
        expect(findSettingsPortal().props('to')).toBe('super-sidebar-settings-disclosure');
      });

      it('does not render non-settings sections', () => {
        const sectionTitles = findNonStaticSectionItems().wrappers.map(
          (w) => w.props('item').title,
        );
        expect(sectionTitles).not.toContain('With subitems');
        expect(sectionTitles).not.toContain('Also with subitems');
      });
    });

    describe.each`
      panelType
      ${'your_work'}
      ${'explore'}
    `('with panelType=$panelType', ({ panelType }) => {
      beforeEach(() => {
        createWrapper({
          items: menuItems,
          panelType,
          provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
        });
      });

      it('renders all non-static items', () => {
        expect(findNonStaticSectionItems().length).toBeGreaterThan(1);
      });
    });

    it('hides unpinned items for logged-out users too', () => {
      createWrapper({
        items: menuItems,
        panelType: 'project',
        isLoggedIn: false,
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      const sections = findNonStaticSectionItems();
      expect(sections).toHaveLength(1);
      expect(sections.at(0).props('item').id).toBe('settings_menu');
    });

    it('hides the main menu separator', () => {
      createWrapper({
        items: menuItems,
        panelType: 'project',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findMainMenuSeparator().exists()).toBe(false);
    });

    it('does not hide unpinned items for organization panel', () => {
      createWrapper({
        items: menuItems,
        panelType: 'organization',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findNonStaticSectionItems().length).toBeGreaterThan(1);
    });

    it('renders organization sections in place, not as disclosures', () => {
      createWrapper({
        items: menuItems,
        panelType: 'organization',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findNonStaticSectionItems().wrappers.map((w) => w.props('disclosure'))).not.toContain(
        true,
      );
      expect(findSettingsPortal().exists()).toBe(false);
    });

    it('still renders the pinned section and feature library trigger', () => {
      createWrapper({
        items: menuItems,
        panelType: 'project',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findPinnedSection().exists()).toBe(true);
      expect(wrapper.findByTestId('feature-library-trigger').exists()).toBe(true);
    });
  });

  describe('Current page nav item', () => {
    const activeItem = { id: 22, title: 'Active subitem', is_active: true };

    const itemsWithActiveSubitem = [
      { id: 1, title: 'No subitems' },
      { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Subitem' }, activeItem] },
      {
        id: 'settings_menu',
        title: 'Settings',
        items: [{ id: 'settings_general', title: 'General' }],
      },
    ];

    const findCurrentPageSection = () => wrapper.findByTestId('current-page-section');

    const createPinnedOnlyWrapper = ({
      items = itemsWithActiveSubitem,
      pinnedItemIds = [],
      glFeatures = {},
      ...options
    } = {}) =>
      createWrapper({
        items,
        pinnedItemIds,
        panelType: 'project',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true, ...glFeatures } },
        ...options,
      });

    it('renders the active item when it is not pinned', () => {
      createPinnedOnlyWrapper();

      expect(findCurrentPageSection().findComponent(NavItem).props('item')).toEqual(activeItem);
    });

    it('names the list so the item reads as the current page', () => {
      // Attached to the document so the accessible name computation can resolve
      // the sibling section's aria-labelledby idref, which points outside this
      // component.
      createPinnedOnlyWrapper({ attachTo: document.body });

      expect(wrapper.findByRole('list', { name: 'Current page' }).exists()).toBe(true);
    });

    it('is not rendered when the active item is already pinned', () => {
      createPinnedOnlyWrapper({ pinnedItemIds: [activeItem.id] });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered when unpinned items are still shown', () => {
      createPinnedOnlyWrapper({
        glFeatures: { hideUnpinnedSidebarItems: false, featureLibraryModal: true },
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered when the active item is in the settings section', () => {
      createPinnedOnlyWrapper({
        items: [
          { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Subitem' }] },
          {
            id: 'settings_menu',
            title: 'Settings',
            items: [{ id: 'settings_general', title: 'General', is_active: true }],
          },
        ],
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered when the active item is a static item', () => {
      createPinnedOnlyWrapper({
        items: [
          { id: 1, title: 'No subitems', is_active: true },
          { id: 2, title: 'With subitems', items: [{ id: 21, title: 'Subitem' }] },
        ],
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered when the active item is hidden in the sidebar', () => {
      createPinnedOnlyWrapper({
        items: [
          {
            id: 2,
            title: 'With subitems',
            items: [{ ...activeItem, link_classes: HIDDEN_NAV_ITEM_CLASS }],
          },
        ],
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    // On group work items, both the visible issue list and the hidden epic list
    // are active. The visible one must win.
    it('prefers the visible item when a hidden item is active too', () => {
      createPinnedOnlyWrapper({
        items: [
          {
            id: 2,
            title: 'With subitems',
            items: [
              {
                id: 20,
                title: 'Hidden active',
                is_active: true,
                link_classes: HIDDEN_NAV_ITEM_CLASS,
              },
              activeItem,
            ],
          },
        ],
      });

      expect(findCurrentPageSection().findComponent(NavItem).props('item')).toEqual(activeItem);
    });

    // A group that still has the legacy group_epic_list pinned shows that hidden
    // item in the pinned section, so its visible twin must not be surfaced again.
    it('is not rendered when a pinned item links to the same page', () => {
      createPinnedOnlyWrapper({
        items: [
          {
            id: 2,
            title: 'With subitems',
            items: [
              {
                id: 20,
                title: 'Hidden active',
                link: '/work_items',
                is_active: true,
                link_classes: HIDDEN_NAV_ITEM_CLASS,
              },
              { ...activeItem, link: '/work_items' },
            ],
          },
        ],
        pinnedItemIds: [20],
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered when no item is active', () => {
      createPinnedOnlyWrapper({ items: menuItems });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered on the organization panel', () => {
      createWrapper({
        items: itemsWithActiveSubitem,
        pinnedItemIds: [],
        panelType: 'organization',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    it('is not rendered on panels that do not support pins', () => {
      createWrapper({
        items: itemsWithActiveSubitem,
        pinnedItemIds: [],
        panelType: 'your_work',
        provide: { glFeatures: { hideUnpinnedSidebarItems: true } },
      });

      expect(findCurrentPageSection().exists()).toBe(false);
    });

    describe('when the item emits pin-add', () => {
      let axiosMock;

      beforeEach(async () => {
        axiosMock = new MockAdapter(axios);
        axiosMock.onPut().reply(HTTP_STATUS_OK, [activeItem.id]);
        createPinnedOnlyWrapper();

        findCurrentPageSection()
          .findComponent(NavItem)
          .vm.$emit('pin-add', activeItem.id, activeItem.title);
        await waitForPromises();
      });

      afterEach(() => {
        axiosMock.restore();
      });

      it('moves the item into the pinned section', () => {
        expect(findCurrentPageSection().exists()).toBe(false);
        expect(findPinnedSection().props('items')).toEqual([activeItem]);
      });
    });
  });
});

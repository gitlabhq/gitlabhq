import { GlButton, GlTabs } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MembersApp from '~/members/components/app.vue';
import MembersTabs from '~/members/components/members_tabs.vue';
import {
  ACTIVE_TAB_QUERY_PARAM_NAME,
  CONTEXT_TYPE,
  FILTERED_SEARCH_TOKEN_GROUPS_WITH_INHERITED_PERMISSIONS,
  MEMBERS_TAB_TYPES,
  TAB_QUERY_PARAM_VALUES,
} from '~/members/constants';
import { pagination } from '../mock_data';

describe('MembersTabs', () => {
  Vue.use(Vuex);

  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  let fetchMembersMock;

  const createComponent = ({
    totalItems = 10,
    provide = {},
    directMembersState = {},
    includeDirectMembersModule = true,
  } = {}) => {
    fetchMembersMock = jest.fn();

    const modules = {
      [MEMBERS_TAB_TYPES.user]: {
        namespaced: true,
        state: {
          pagination: {
            ...pagination,
            totalItems,
          },
          filteredSearchBar: {
            searchParam: 'search',
          },
        },
      },
      [MEMBERS_TAB_TYPES.group]: {
        namespaced: true,
        state: {
          pagination: {
            ...pagination,
            totalItems,
            paramName: 'groups_page',
          },
          filteredSearchBar: {
            searchParam: 'search_groups',
            tokens: [FILTERED_SEARCH_TOKEN_GROUPS_WITH_INHERITED_PERMISSIONS.type],
          },
        },
      },
      [MEMBERS_TAB_TYPES.invite]: {
        namespaced: true,
        state: {
          pagination: {
            ...pagination,
            totalItems,
            paramName: 'invited_page',
          },
          filteredSearchBar: {
            searchParam: 'search_invited',
          },
        },
      },
      [MEMBERS_TAB_TYPES.accessRequest]: {
        namespaced: true,
        state: {
          pagination: {
            ...pagination,
            totalItems,
            paramName: 'access_requests_page',
          },
          filteredSearchBar: {
            searchParam: 'search_access_requests',
          },
        },
      },
    };

    // The Direct members tab is only wired up on the project members page. Omit
    // its store module to simulate the group members page (shared `TABS` array).
    if (includeDirectMembersModule) {
      modules[MEMBERS_TAB_TYPES.directMembers] = {
        namespaced: true,
        actions: {
          fetchMembers: fetchMembersMock,
        },
        state: {
          pagination: {
            ...pagination,
            totalItems,
            paramName: 'direct_members_page',
          },
          filteredSearchBar: {
            searchParam: 'search_direct_members',
          },
          ...directMembersState,
        },
      };
    }

    const store = new Vuex.Store({ modules });

    wrapper = mountExtended(MembersTabs, {
      store,
      stubs: ['members-app'],
      provide: {
        canManageMembers: true,
        canManageAccessRequests: true,
        canExportMembers: true,
        exportCsvPath: '',
        context: CONTEXT_TYPE.GROUP,
        ...provide,
      },
    });

    return nextTick();
  };

  const findTabs = () => wrapper.findAllByRole('tab').wrappers;
  const findTabByText = (text) => findTabs().find((tab) => tab.text().includes(text));
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });
  const findExportButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    setWindowLocation('https://localhost');
  });

  it('renders `GlTabs` with `syncActiveTabWithQueryParams` and `queryParamName` props set', async () => {
    await createComponent();

    const glTabsComponent = wrapper.findComponent(GlTabs);

    expect(glTabsComponent.exists()).toBe(true);
    expect(glTabsComponent.props()).toMatchObject({
      syncActiveTabWithQueryParams: true,
      queryParamName: ACTIVE_TAB_QUERY_PARAM_NAME,
    });
  });

  describe('when tabs have a count', () => {
    it('renders tabs with count', async () => {
      await createComponent();

      const tabs = findTabs();

      expect(tabs[0].text()).toBe('Members  10');
      expect(tabs[1].text()).toBe('Direct members  10');
      expect(tabs[2].text()).toBe('Groups  10');
      expect(tabs[3].text()).toBe('Pending invitations  10');
      expect(tabs[4].text()).toBe('Access requests  10');
      expect(findActiveTab().text()).toContain('Members');
    });

    it('renders `MembersApp` and passes `namespace` and `tabQueryParamValue` props', async () => {
      await createComponent();

      const membersApps = wrapper.findAllComponents(MembersApp).wrappers;

      expect(membersApps[0].props('namespace')).toBe(MEMBERS_TAB_TYPES.user);
      expect(membersApps[1].props('namespace')).toBe(MEMBERS_TAB_TYPES.group);
      expect(membersApps[2].props('namespace')).toBe(MEMBERS_TAB_TYPES.invite);
      expect(membersApps[3].props('namespace')).toBe(MEMBERS_TAB_TYPES.accessRequest);

      expect(membersApps[1].props('tabQueryParamValue')).toBe(TAB_QUERY_PARAM_VALUES.group);
      expect(membersApps[2].props('tabQueryParamValue')).toBe(TAB_QUERY_PARAM_VALUES.invite);
      expect(membersApps[3].props('tabQueryParamValue')).toBe(TAB_QUERY_PARAM_VALUES.accessRequest);
    });
  });

  describe('when tabs do not have a count', () => {
    it('renders `Members` and always-shown `Direct members` tabs only', async () => {
      await createComponent({ totalItems: 0 });

      // `Direct members` is always shown because its members are fetched lazily
      // on activation, so its count is 0 on initial load.
      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Direct members')).not.toBeUndefined();
      expect(findTabByText('Groups')).toBeUndefined();
      expect(findTabByText('Pending invitations')).toBeUndefined();
      expect(findTabByText('Access requests')).toBeUndefined();
    });

    it('does not show the always-shown `Direct members` tab when it has no store module', async () => {
      // Simulates the group members page, which shares the `TABS` array but does
      // not build a `directMembers` store module, so `alwaysShow` must not surface
      // an empty, data-less tab there.
      await createComponent({ totalItems: 0, includeDirectMembersModule: false });

      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Direct members')).toBeUndefined();
    });
  });

  describe('when url param matches `filteredSearchBar.searchParam`', () => {
    beforeEach(() => {
      setWindowLocation('?search_groups=foo+bar');
    });

    it('shows tab that corresponds to search param', async () => {
      await createComponent({ totalItems: 0 });

      expect(findTabByText('Groups')).not.toBeUndefined();
    });
  });

  describe('when url param matches `filteredSearchBar.tokens`', () => {
    beforeEach(() => {
      setWindowLocation('?groups_with_inherited_permissions=exclude');
    });

    it('shows tab that corresponds to filtered search token', async () => {
      await createComponent({ totalItems: 0 });

      expect(findTabByText('Groups')).not.toBeUndefined();
    });
  });

  describe('when `canManageMembers` is `false`', () => {
    it('shows all tabs except `Pending invitations` and `Access requests`', async () => {
      await createComponent({
        provide: { canManageMembers: false, canManageAccessRequests: false },
      });

      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Direct members')).not.toBeUndefined();
      expect(findTabByText('Groups')).not.toBeUndefined();
      expect(findTabByText('Pending invitations')).toBeUndefined();
      expect(findTabByText('Access requests')).toBeUndefined();
    });
  });

  describe('when `canExportMembers` is true', () => {
    it('shows the CSV export button with export path', async () => {
      await createComponent({ provide: { canExportMembers: true, exportCsvPath: 'foo' } });

      expect(findExportButton().attributes('href')).toBe('foo');
    });
  });

  describe('when `canExportMembers` is false', () => {
    it('does not show the CSV export button', async () => {
      await createComponent({ provide: { canExportMembers: false } });

      expect(findExportButton().exists()).toBe(false);
    });
  });

  it.each`
    tab                 | testId                       | href
    ${'Members'}        | ${'user-tab-title'}          | ${'https://localhost/'}
    ${'Direct members'} | ${'directMembers-tab-title'} | ${'https://localhost/?tab=direct_members'}
    ${'Groups'}         | ${'group-tab-title'}         | ${'https://localhost/?tab=groups'}
    ${'Invite'}         | ${'invite-tab-title'}        | ${'https://localhost/?tab=invited'}
    ${'Access Request'} | ${'accessRequest-tab-title'} | ${'https://localhost/?tab=access_requests'}
  `('sets correct link attributes for $tab tab', async ({ testId, href }) => {
    await createComponent();

    const tabTitleContainer = wrapper.findByTestId(testId).element.parentElement;

    expect(tabTitleContainer.href).toBe(href);
  });

  describe('when a search/filter param from another tab is present in the URL', () => {
    beforeEach(() => {
      setWindowLocation('?search=luba&search_groups=foo');
    });

    it.each`
      tab                 | testId                       | href
      ${'Members'}        | ${'user-tab-title'}          | ${'https://localhost/'}
      ${'Direct members'} | ${'directMembers-tab-title'} | ${'https://localhost/?tab=direct_members'}
      ${'Groups'}         | ${'group-tab-title'}         | ${'https://localhost/?tab=groups'}
    `(
      'clears all tabs search/token params when switching to $tab tab',
      async ({ testId, href }) => {
        await createComponent();

        const tabTitleContainer = wrapper.findByTestId(testId).element.parentElement;

        expect(tabTitleContainer.href).toBe(href);
      },
    );
  });

  describe.each`
    tab                 | testId
    ${'Members'}        | ${'user-tab-title'}
    ${'Direct members'} | ${'directMembers-tab-title'}
    ${'Groups'}         | ${'group-tab-title'}
    ${'Invite'}         | ${'invite-tab-title'}
    ${'Access Request'} | ${'accessRequest-tab-title'}
  `('when $tab tab is clicked', ({ testId }) => {
    let mockEvent;

    beforeEach(async () => {
      setWindowLocation('https://localhost/?page=2');

      mockEvent = { stopPropagation: jest.fn() };
      await createComponent();

      await wrapper.findByTestId(testId).trigger('click', mockEvent);
    });

    // This ensures we bypass the click listeners added by `GlTab` and that we trigger the redirect via the anchor tag directly.
    it('stops event propagation', () => {
      expect(mockEvent.stopPropagation).toHaveBeenCalled();
    });
  });

  describe('lazy members fetch on tab activation', () => {
    it('fetches members when a lazy tab (with `membersPath`) becomes active', async () => {
      setWindowLocation('?tab=direct_members&search_direct_members=luba&direct_members_page=2');

      await createComponent({
        directMembersState: { membersPath: '/foo-bar/-/project_members.json' },
      });
      // GlTabs syncs the active tab from the query param after mount.
      await nextTick();

      expect(fetchMembersMock).toHaveBeenCalledTimes(1);
      expect(fetchMembersMock.mock.calls[0][1]).toEqual({
        search_direct_members: 'luba',
        direct_members_page: '2',
      });
    });

    it('does not fetch when the lazy tab has already been loaded', async () => {
      setWindowLocation('?tab=direct_members');

      await createComponent({
        directMembersState: {
          membersPath: '/foo-bar/-/project_members.json',
          loadRequested: true,
        },
      });
      await nextTick();

      expect(fetchMembersMock).not.toHaveBeenCalled();
    });

    it('does not fetch when the active tab has no `membersPath`', async () => {
      setWindowLocation('?tab=direct_members');

      await createComponent();
      await nextTick();

      expect(fetchMembersMock).not.toHaveBeenCalled();
    });

    it('does not fetch the lazy tab while another tab is active', async () => {
      setWindowLocation('https://localhost/');

      await createComponent({
        directMembersState: { membersPath: '/foo-bar/-/project_members.json' },
      });

      expect(fetchMembersMock).not.toHaveBeenCalled();
    });
  });
});

import { GlTabs, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MembersApp from '~/members/components/app.vue';
import MembersTabs from '~/members/components/members_tabs.vue';
import {
  MEMBERS_TAB_TYPES,
  TAB_QUERY_PARAM_VALUES,
  ACTIVE_TAB_QUERY_PARAM_NAME,
  FILTERED_SEARCH_TOKEN_GROUPS_WITH_INHERITED_PERMISSIONS,
  CONTEXT_TYPE,
} from '~/members/constants';
import { pagination } from '../mock_data';

describe('MembersTabs', () => {
  Vue.use(Vuex);

  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createComponent = ({ totalItems = 10, provide = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
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
      },
    });

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
      expect(tabs[1].text()).toBe('Groups  10');
      expect(tabs[2].text()).toBe('Pending invitations  10');
      expect(tabs[3].text()).toBe('Access requests  10');
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
    it('only renders `Members` tab', async () => {
      await createComponent({ totalItems: 0 });

      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Groups')).toBeUndefined();
      expect(findTabByText('Pending invitations')).toBeUndefined();
      expect(findTabByText('Access requests')).toBeUndefined();
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
  });

  describe('when `canManageMembers` is `false`', () => {
    it('shows all tabs except `Pending invitations` and `Access requests`', async () => {
      await createComponent({
        provide: { canManageMembers: false, canManageAccessRequests: false },
      });

      expect(findTabByText('Members')).not.toBeUndefined();
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
});

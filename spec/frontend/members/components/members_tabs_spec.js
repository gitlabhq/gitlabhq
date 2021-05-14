import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MembersApp from '~/members/components/app.vue';
import MembersTabs from '~/members/components/members_tabs.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { pagination } from '../mock_data';

describe('MembersApp', () => {
  Vue.use(Vuex);

  let wrapper;

  const createComponent = ({ totalItems = 10, options = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
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
        [MEMBER_TYPES.group]: {
          namespaced: true,
          state: {
            pagination: {
              ...pagination,
              totalItems,
              paramName: 'groups_page',
            },
            filteredSearchBar: {
              searchParam: 'search_groups',
            },
          },
        },
        [MEMBER_TYPES.invite]: {
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
        [MEMBER_TYPES.accessRequest]: {
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
      },
      ...options,
    });

    return nextTick();
  };

  const findTabs = () => wrapper.findAllByRole('tab').wrappers;
  const findTabByText = (text) => findTabs().find((tab) => tab.text().includes(text));
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });

  beforeEach(() => {
    delete window.location;
    window.location = new URL('https://localhost');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when tabs have a count', () => {
    it('renders tabs with count', async () => {
      await createComponent();

      const tabs = findTabs();

      expect(tabs[0].text()).toBe('Members  10');
      expect(tabs[1].text()).toBe('Groups  10');
      expect(tabs[2].text()).toBe('Invited  10');
      expect(tabs[3].text()).toBe('Access requests  10');
      expect(findActiveTab().text()).toContain('Members');
    });

    it('renders `MembersApp` and passes `namespace` prop', async () => {
      await createComponent();

      const membersApps = wrapper.findAllComponents(MembersApp).wrappers;

      expect(membersApps[0].attributes('namespace')).toBe(MEMBER_TYPES.user);
      expect(membersApps[1].attributes('namespace')).toBe(MEMBER_TYPES.group);
      expect(membersApps[2].attributes('namespace')).toBe(MEMBER_TYPES.invite);
      expect(membersApps[3].attributes('namespace')).toBe(MEMBER_TYPES.accessRequest);
    });
  });

  describe('when tabs do not have a count', () => {
    it('only renders `Members` tab', async () => {
      await createComponent({ totalItems: 0 });

      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Groups')).toBeUndefined();
      expect(findTabByText('Invited')).toBeUndefined();
      expect(findTabByText('Access requests')).toBeUndefined();
    });
  });

  describe('when url param matches `filteredSearchBar.searchParam`', () => {
    beforeEach(() => {
      window.location.search = '?search_groups=foo+bar';
    });

    const expectGroupsTabActive = () => {
      expect(findActiveTab().text()).toContain('Groups');
    };

    describe('when tab has a count', () => {
      it('sets tab that corresponds to search param as active tab', async () => {
        await createComponent();

        expectGroupsTabActive();
      });
    });

    describe('when tab does not have a count', () => {
      it('sets tab that corresponds to search param as active tab', async () => {
        await createComponent({ totalItems: 0 });

        expectGroupsTabActive();
      });
    });
  });

  describe('when url param matches `pagination.paramName`', () => {
    beforeEach(() => {
      window.location.search = '?invited_page=2';
    });

    const expectInvitedTabActive = () => {
      expect(findActiveTab().text()).toContain('Invited');
    };

    describe('when tab has a count', () => {
      it('sets tab that corresponds to pagination param as active tab', async () => {
        await createComponent();

        expectInvitedTabActive();
      });
    });

    describe('when tab does not have a count', () => {
      it('sets tab that corresponds to pagination param as active tab', async () => {
        await createComponent({ totalItems: 0 });

        expectInvitedTabActive();
      });
    });
  });

  describe('when `canManageMembers` is `false`', () => {
    it('shows all tabs except `Invited` and `Access requests`', async () => {
      await createComponent({ options: { provide: { canManageMembers: false } } });

      expect(findTabByText('Members')).not.toBeUndefined();
      expect(findTabByText('Groups')).not.toBeUndefined();
      expect(findTabByText('Invited')).toBeUndefined();
      expect(findTabByText('Access requests')).toBeUndefined();
    });
  });
});

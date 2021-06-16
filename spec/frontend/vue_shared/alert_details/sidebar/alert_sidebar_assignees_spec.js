import { GlDropdownItem } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SidebarAssignee from '~/vue_shared/alert_details/components/sidebar/sidebar_assignee.vue';
import SidebarAssignees from '~/vue_shared/alert_details/components/sidebar/sidebar_assignees.vue';
import AlertSetAssignees from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Assignees', () => {
  let wrapper;
  let mock;

  const mockPath = '/-/autocomplete/users.json';
  const mockUsers = [
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      id: 1,
      name: 'User 1',
      username: 'root',
      webUrl: 'https://gitlab:3443/root',
    },
    {
      avatar_url:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      id: 2,
      name: 'User 2',
      username: 'not-root',
      webUrl: 'https://gitlab:3443/non-root',
    },
  ];

  const findAssigned = () => wrapper.findByTestId('assigned-users');
  const findDropdown = () => wrapper.findComponent(GlDropdownItem);
  const findSidebarIcon = () => wrapper.findByTestId('assignees-icon');
  const findUnassigned = () => wrapper.findByTestId('unassigned-users');

  function mountComponent({
    data,
    users = [],
    isDropdownSearching = false,
    sidebarCollapsed = true,
    loading = false,
    stubs = {},
  } = {}) {
    wrapper = shallowMountExtended(SidebarAssignees, {
      data() {
        return {
          users,
          isDropdownSearching,
        };
      },
      propsData: {
        alert: { ...mockAlert },
        ...data,
        sidebarCollapsed,
        projectPath: 'projectPath',
        projectId: '1',
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
          queries: {
            alert: {
              loading,
            },
          },
        },
      },
      stubs,
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  describe('sidebar expanded', () => {
    const mockUpdatedMutationResult = {
      data: {
        alertSetAssignees: {
          errors: [],
          alert: {
            assigneeUsernames: ['root'],
          },
        },
      },
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);

      mock.onGet(mockPath).replyOnce(200, mockUsers);
      mountComponent({
        data: { alert: mockAlert },
        sidebarCollapsed: false,
        loading: false,
        users: mockUsers,
        stubs: {
          SidebarAssignee,
        },
      });
    });

    it('renders a unassigned option', async () => {
      wrapper.setData({ isDropdownSearching: false });
      await wrapper.vm.$nextTick();
      expect(findDropdown().text()).toBe('Unassigned');
    });

    it('does not display the collapsed sidebar icon', () => {
      expect(findSidebarIcon().exists()).toBe(false);
    });

    it('calls `$apollo.mutate` with `AlertSetAssignees` mutation and variables containing `iid`, `assigneeUsernames`, & `projectPath`', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);
      wrapper.setData({ isDropdownSearching: false });

      await wrapper.vm.$nextTick();
      wrapper.find(SidebarAssignee).vm.$emit('update-alert-assignees', 'root');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: AlertSetAssignees,
        variables: {
          iid: '1527542',
          assigneeUsernames: ['root'],
          fullPath: 'projectPath',
        },
      });
    });

    it('emits an error when request contains error messages', () => {
      wrapper.setData({ isDropdownSearching: false });
      const errorMutationResult = {
        data: {
          issuableSetAssignees: {
            errors: ['There was a problem for sure.'],
            alert: {},
          },
        },
      };

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(errorMutationResult);
      return wrapper.vm
        .$nextTick()
        .then(() => {
          const SideBarAssigneeItem = wrapper.findAll(SidebarAssignee).at(0);
          SideBarAssigneeItem.vm.$emit('update-alert-assignees');
        })
        .then(() => {
          expect(wrapper.emitted('alert-error')).toBeDefined();
        });
    });

    it('stops updating and cancels loading when the request fails', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));
      wrapper.vm.updateAlertAssignees('root');
      expect(findUnassigned().text()).toBe('assign yourself');
    });

    it('shows a user avatar, username and full name when a user is set', () => {
      mountComponent({
        data: { alert: mockAlerts[1] },
        sidebarCollapsed: false,
        loading: false,
        stubs: {
          SidebarAssignee,
        },
      });

      expect(findAssigned().find('img').attributes('src')).toBe('/url');
      expect(findAssigned().find('.dropdown-menu-user-full-name').text()).toBe('root');
      expect(findAssigned().find('.dropdown-menu-user-username').text()).toBe('@root');
    });
  });

  describe('sidebar collapsed', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      mock.onGet(mockPath).replyOnce(200, mockUsers);

      mountComponent({
        data: { alert: mockAlert },
        loading: false,
        users: mockUsers,
        stubs: {
          SidebarAssignee,
        },
      });
    });
    it('does not display the status dropdown', () => {
      expect(findDropdown().exists()).toBe(false);
    });

    it('does display the collapsed sidebar icon', () => {
      expect(findSidebarIcon().exists()).toBe(true);
    });
  });
});

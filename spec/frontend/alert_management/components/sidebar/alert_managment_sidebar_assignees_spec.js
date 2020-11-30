import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { GlDropdownItem } from '@gitlab/ui';
import SidebarAssignee from '~/alert_management/components/sidebar/sidebar_assignee.vue';
import SidebarAssignees from '~/alert_management/components/sidebar/sidebar_assignees.vue';
import AlertSetAssignees from '~/alert_management/graphql/mutations/alert_set_assignees.mutation.graphql';
import mockAlerts from '../../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Assignees', () => {
  let wrapper;
  let mock;

  function mountComponent({
    data,
    users = [],
    isDropdownSearching = false,
    sidebarCollapsed = true,
    loading = false,
    stubs = {},
  } = {}) {
    wrapper = shallowMount(SidebarAssignees, {
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

  const findAssigned = () => wrapper.find('[data-testid="assigned-users"]');
  const findUnassigned = () => wrapper.find('[data-testid="unassigned-users"]');

  describe('updating the alert status', () => {
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
      const path = '/-/autocomplete/users.json';
      const users = [
        {
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          id: 1,
          name: 'User 1',
          username: 'root',
        },
        {
          avatar_url:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          id: 2,
          name: 'User 2',
          username: 'not-root',
        },
      ];

      mock.onGet(path).replyOnce(200, users);
      mountComponent({
        data: { alert: mockAlert },
        sidebarCollapsed: false,
        loading: false,
        users,
        stubs: {
          SidebarAssignee,
        },
      });
    });

    it('renders a unassigned option', async () => {
      wrapper.setData({ isDropdownSearching: false });
      await wrapper.vm.$nextTick();
      expect(wrapper.find(GlDropdownItem).text()).toBe('Unassigned');
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
          projectPath: 'projectPath',
        },
      });
    });

    it('emits an error when request contains error messages', () => {
      wrapper.setData({ isDropdownSearching: false });
      const errorMutationResult = {
        data: {
          alertSetAssignees: {
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

      expect(
        findAssigned()
          .find('img')
          .attributes('src'),
      ).toBe('/url');
      expect(
        findAssigned()
          .find('.dropdown-menu-user-full-name')
          .text(),
      ).toBe('root');
      expect(
        findAssigned()
          .find('.dropdown-menu-user-username')
          .text(),
      ).toBe('@root');
    });
  });
});

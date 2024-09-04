import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAvatar, GlDropdownItem } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import SidebarAssignee from '~/vue_shared/alert_details/components/sidebar/sidebar_assignee.vue';
import SidebarAssignees from '~/vue_shared/alert_details/components/sidebar/sidebar_assignees.vue';
import AlertSetAssignees from '~/vue_shared/alert_details/graphql/mutations/alert_set_assignees.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Assignees', () => {
  let wrapper;
  let requestHandlers;
  let mock;

  const mockPath = '/-/autocomplete/users.json';
  const mockUrlRoot = '/gitlab';
  const expectedUrl = `${mockUrlRoot}${mockPath}`;

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

  const mockDefaultHandler = (errors = []) =>
    jest.fn().mockResolvedValue({
      data: {
        issuableSetAssignees: {
          errors,
          issuable: {
            id: 'id',
            iid: 'iid',
            assignees: {
              nodes: [],
            },
            notes: {
              nodes: [],
            },
          },
        },
      },
    });
  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);
    requestHandlers = handlers;

    return createMockApollo([[AlertSetAssignees, handlers]]);
  };

  function mountComponent({
    props,
    sidebarCollapsed = true,
    handlers = mockDefaultHandler(),
  } = {}) {
    wrapper = shallowMountExtended(SidebarAssignees, {
      apolloProvider: createMockApolloProvider(handlers),
      propsData: {
        alert: { ...mockAlert },
        ...props,
        sidebarCollapsed,
        projectPath: 'projectPath',
        projectId: '1',
      },
    });
  }

  describe('sidebar expanded', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      window.gon = {
        relative_url_root: mockUrlRoot,
      };

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, mockUsers);
      mountComponent({
        props: { alert: mockAlert },
        sidebarCollapsed: false,
      });
    });

    it('renders a unassigned option', async () => {
      await waitForPromises();
      expect(findDropdown().text()).toBe('Unassigned');
    });

    it('does not display the collapsed sidebar icon', () => {
      expect(findSidebarIcon().exists()).toBe(false);
    });

    it('calls `AlertSetAssignees` mutation and variables containing `iid`, `assigneeUsernames`, & `projectPath`', async () => {
      await waitForPromises();
      wrapper.findComponent(SidebarAssignee).vm.$emit('update-alert-assignees', 'root');

      expect(requestHandlers).toHaveBeenCalledWith({
        iid: '1527542',
        assigneeUsernames: ['root'],
        fullPath: 'projectPath',
      });
    });

    it('emits an error when request contains error messages', async () => {
      mountComponent({
        sidebarCollapsed: false,
        handlers: mockDefaultHandler(['There was a problem for sure.']),
      });
      await waitForPromises();

      const SideBarAssigneeItem = wrapper.findAllComponents(SidebarAssignee).at(0);
      await SideBarAssigneeItem.vm.$emit('update-alert-assignees');

      await waitForPromises();
      expect(wrapper.emitted('alert-error')).toHaveLength(1);
    });

    it('stops updating and cancels loading when the request fails', () => {
      expect(findUnassigned().text()).toBe('assign yourself');
    });

    it('shows a user avatar, username and full name when a user is set', () => {
      mountComponent({
        props: { alert: mockAlerts[1] },
      });

      expect(findAssigned().findComponent(GlAvatar).props('src')).toBe('/url');
      expect(findAssigned().find('.dropdown-menu-user-full-name').text()).toBe('root');
      expect(findAssigned().find('.dropdown-menu-user-username').text()).toBe('@root');
    });
  });

  describe('sidebar collapsed', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      mock.onGet(expectedUrl).replyOnce(HTTP_STATUS_OK, mockUsers);

      mountComponent({
        props: { alert: mockAlert },
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

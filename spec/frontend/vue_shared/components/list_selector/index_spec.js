import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import Api from '~/api';
import RestApi from '~/rest_api';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import UserItem from '~/vue_shared/components/list_selector/user_item.vue';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import ProjectItem from '~/vue_shared/components/list_selector/project_item.vue';
import DeployKeyItem from '~/vue_shared/components/list_selector/deploy_key_item.vue';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import getAvailableDeployKeys from '~/vue_shared/components/list_selector/queries/available_deploy_keys.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { ACCESS_LEVEL_REPORTER_INTEGER } from '~/access_level/constants';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { USERS_RESPONSE_MOCK, GROUPS_RESPONSE_MOCK, DEPLOY_KEYS_RESPONSE_MOCK } from './mock_data';

jest.mock('~/alert');
jest.mock('~/api');
jest.mock('~/rest_api', () => ({
  getProjects: jest.fn().mockResolvedValue({
    data: [
      { name: 'Project 1', id: '1' },
      { name: 'Project 2', id: '2' },
    ],
  }),
}));
Vue.use(VueApollo);

describe('List Selector spec', () => {
  let wrapper;
  let fakeApollo;
  let axiosMock;
  const projectPath = 'some/project/path';

  const USERS_MOCK_PROPS = {
    projectPath,
    groupPath: 'some/group/path',
    usersQueryOptions: { active: true },
    type: 'users',
  };

  const GROUPS_MOCK_PROPS = {
    projectPath,
    type: 'groups',
  };

  const DEPLOY_KEYS_MOCK_PROPS = {
    projectPath,
    type: 'deployKeys',
  };

  const PROJECTS_MOCK_PROPS = {
    type: 'projects',
  };

  const groupsAutocompleteQuerySuccess = jest.fn().mockResolvedValue(GROUPS_RESPONSE_MOCK);
  const deployKeysQuerySuccess = jest.fn().mockResolvedValue(DEPLOY_KEYS_RESPONSE_MOCK);

  const createComponent = async (
    props,
    apolloQuery = groupsAutocompleteQuery,
    apolloResolver = groupsAutocompleteQuerySuccess,
  ) => {
    fakeApollo = createMockApollo([[apolloQuery, apolloResolver]]);

    wrapper = mountExtended(ListSelector, {
      apolloProvider: fakeApollo,
      propsData: {
        ...props,
      },
      stubs: { CrudComponent },
    });

    await waitForPromises();
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findTitle = () => findCrudComponent().props('title');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAllListBoxComponents = () => wrapper.findAllComponents(GlCollapsibleListbox);
  const findSearchResultsDropdown = () => findAllListBoxComponents().at(0);
  const findNamespaceDropdown = () => wrapper.findByTestId('namespace-dropdown');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllUserComponents = () => wrapper.findAllComponents(UserItem);
  const findAllGroupComponents = () => wrapper.findAllComponents(GroupItem);
  const findAllProjectComponents = () => wrapper.findAllComponents(ProjectItem);
  const findAllDeployKeyComponents = () => wrapper.findAllComponents(DeployKeyItem);

  beforeEach(() => {
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(USERS_RESPONSE_MOCK);
    jest.spyOn(Api, 'projectGroups').mockResolvedValue(GROUPS_RESPONSE_MOCK.data.groups.nodes);
  });

  describe('empty state', () => {
    beforeEach(() => createComponent(USERS_MOCK_PROPS));

    it('renders an empty placeholder', () => {
      expect(wrapper.findByText('No users have been added.').exists()).toBe(true);
    });
  });

  describe('Users type', () => {
    beforeEach(() => createComponent(USERS_MOCK_PROPS));

    it('renders a crud component', () => {
      expect(findCrudComponent().exists()).toBe(true);
    });

    it('renders a correct title', () => {
      expect(findTitle()).toContain('Users');
    });

    it('renders the correct icon', () => {
      expect(findIcon().props('name')).toBe('user');
    });

    it('renders a Search box component', () => {
      expect(findSearchBox().exists()).toBe(true);
    });

    it('does not call query when search box has not received an input', () => {
      expect(Api.projectUsers).not.toHaveBeenCalled();
      expect(findAllUserComponents().length).toBe(0);
    });

    describe('namespace dropdown rendering', () => {
      beforeEach(() => createComponent({ ...USERS_MOCK_PROPS, disableNamespaceDropdown: true }));

      it('does not render namespace dropdown with disableNamespaceDropdown prop', () => {
        expect(findNamespaceDropdown().exists()).toBe(false);
      });
    });

    describe('selected items', () => {
      const selectedUser = { username: 'root' };
      const selectedItems = [selectedUser];
      beforeEach(() => createComponent({ ...USERS_MOCK_PROPS, selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findTitle()).toContain('Users');
        expect(findCrudComponent().props('count')).toBe(1);
      });

      it('renders a user component for each selected item', () => {
        expect(findAllUserComponents().length).toBe(selectedItems.length);
        expect(findAllUserComponents().at(0).props()).toMatchObject({
          data: selectedUser,
          canDelete: true,
        });
      });

      it('emits a delete event when a delete event is emitted from the user component', () => {
        const username = 'root';
        findAllUserComponents().at(0).vm.$emit('delete', username);

        expect(wrapper.emitted('delete')).toEqual([[username]]);
      });
    });
  });

  describe('Groups type', () => {
    beforeEach(() => createComponent(GROUPS_MOCK_PROPS));
    const search = 'foo';

    it('renders a correct title', () => {
      expect(findTitle()).toContain('Groups');
    });

    it('renders the correct icon', () => {
      expect(findIcon().props('name')).toBe('group');
    });

    it('does not call query when search box has not received an input', () => {
      expect(groupsAutocompleteQuerySuccess).not.toHaveBeenCalled();
      expect(findAllGroupComponents().length).toBe(0);
    });

    it('renders two namespace dropdown items', () => {
      expect(findNamespaceDropdown().props('items').length).toBe(2);
    });

    it('does not render namespace dropdown with disableNamespaceDropdown prop set to true', () => {
      createComponent({
        ...GROUPS_MOCK_PROPS,
        disableNamespaceDropdown: true,
      });

      expect(findNamespaceDropdown().exists()).toBe(false);
    });

    describe('searching', () => {
      describe('for default all groups', () => {
        const searchResponse = GROUPS_RESPONSE_MOCK.data.groups.nodes.map((group) => {
          const groupId = getIdFromGraphQLId(group.id);

          return {
            ...group,
            id: groupId,
            value: groupId,
          };
        });

        const emitSearchInput = async () => {
          findSearchBox().vm.$emit('input', search);
          await waitForPromises();
        };

        beforeEach(async () => {
          findNamespaceDropdown().vm.$emit('select', 'false');
          await emitSearchInput();
        });

        it('calls query with correct variables when Search box receives an input', () => {
          expect(groupsAutocompleteQuerySuccess).toHaveBeenCalledWith({
            search,
          });
        });

        it('renders a dropdown for the search results', () => {
          expect(findSearchResultsDropdown().props()).toMatchObject({
            items: searchResponse,
          });
        });

        it('renders a group component for each search result', () => {
          expect(findAllGroupComponents().length).toBe(searchResponse.length);
        });

        it('emits an event when a search result is selected', () => {
          const firstSearchResult = searchResponse[0];
          findSearchResultsDropdown().vm.$emit('select', firstSearchResult.id);

          expect(wrapper.emitted('select')).toEqual([
            [
              {
                __typename: 'Group',
                avatarUrl: null,
                fullName: 'Flightjs',
                id: 33,
                name: 'Flightjs',
                text: 'Flightjs',
                value: 33,
                type: 'group',
              },
            ],
          ]);
        });
      });

      describe('for groups with project access', () => {
        const mockProjectId = 7;
        const mockUrl = '/-/autocomplete/project_groups.json';
        const mockAxiosResponse = [
          { id: 1, avatar_url: null, name: 'group1' },
          { id: 2, avatar_url: null, name: 'group2' },
        ];
        axiosMock = new MockAdapter(axios);

        const emitSearchInput = async () => {
          findSearchBox().vm.$emit('input', search);
          await waitForPromises();
        };

        beforeEach(async () => {
          createComponent({
            ...GROUPS_MOCK_PROPS,
            isGroupsWithProjectAccess: true,
            projectId: mockProjectId,
          });
          axiosMock.onGet(mockUrl).replyOnce(HTTP_STATUS_OK, mockAxiosResponse);
          await emitSearchInput();
        });

        it('calls query with correct variables when Search box receives an input', () => {
          expect(axiosMock.history.get[0].params).toStrictEqual({
            project_id: mockProjectId,
            with_project_access: true,
            search,
          });
        });
      });
    });

    describe('searching based on namespace dropdown selection', () => {
      const searchResponse = GROUPS_RESPONSE_MOCK.data.groups.nodes;

      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
      };

      beforeEach(async () => {
        createComponent({
          ...GROUPS_MOCK_PROPS,
          isProjectScoped: true,
        });

        findNamespaceDropdown().vm.$emit('select', 'true');
        await emitSearchInput();
      });

      it('shows error alert when API fails', async () => {
        jest.spyOn(Api, 'projectGroups').mockRejectedValueOnce();
        await emitSearchInput();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching. Please try again.',
        });
      });

      it('calls query with correct variables when Search box receives an input', () => {
        expect(Api.projectGroups).toHaveBeenCalledWith(USERS_MOCK_PROPS.projectPath, {
          search,
          shared_min_access_level: ACCESS_LEVEL_REPORTER_INTEGER,
          with_shared: true,
        });
      });

      it('renders a List box component with the correct props', () => {
        expect(findSearchResultsDropdown().props('items')).toMatchObject(searchResponse);
      });

      it('renders a group component for each search result', () => {
        expect(findAllGroupComponents().length).toBe(searchResponse.length);
      });

      it('emits an event when a search result is selected', () => {
        const firstSearchResult = searchResponse[0];
        findSearchResultsDropdown().vm.$emit('select', firstSearchResult.id);

        expect(wrapper.emitted('select')).toMatchObject([
          [{ ...firstSearchResult, value: firstSearchResult.id }],
        ]);
      });
    });

    describe('selected items', () => {
      const selectedGroup = { name: 'Flightjs' };
      const selectedItems = [selectedGroup];
      beforeEach(() => createComponent({ ...GROUPS_MOCK_PROPS, selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findTitle()).toContain('Groups');
        expect(findCrudComponent().props('count')).toBe(1);
      });

      it('renders a group component for each selected item', () => {
        expect(findAllGroupComponents().length).toBe(selectedItems.length);
        expect(findAllGroupComponents().at(0).props()).toMatchObject({
          data: selectedGroup,
          canDelete: true,
        });
      });

      it('emits a delete event when a delete event is emitted from the group component', () => {
        const name = 'Flightjs';
        findAllGroupComponents().at(0).vm.$emit('delete', name);

        expect(wrapper.emitted('delete')).toEqual([[name]]);
      });
    });
  });

  describe('Deploy keys type', () => {
    const deployKeysItems = DEPLOY_KEYS_RESPONSE_MOCK.data.project.availableDeployKeys.nodes.map(
      (deployKey) => ({
        ...deployKey,
        id: getIdFromGraphQLId(deployKey.id),
        type: 'deployKeys',
        text: deployKey.title,
        value: getIdFromGraphQLId(deployKey.id),
      }),
    );

    beforeEach(() =>
      createComponent(DEPLOY_KEYS_MOCK_PROPS, getAvailableDeployKeys, deployKeysQuerySuccess),
    );

    it('renders a correct title', () => {
      expect(findTitle()).toContain('Deploy keys');
    });

    it('renders the correct icon', () => {
      expect(findIcon().props('name')).toBe('key');
    });

    describe('searching', () => {
      const search = 'key';
      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
      };

      beforeEach(() => emitSearchInput());

      it('calls query with correct variables when search box receives an input', () => {
        expect(deployKeysQuerySuccess).toHaveBeenCalledWith({
          projectPath,
          titleQuery: search,
        });
      });

      it('renders a dropdown for the search results', () => {
        expect(findSearchResultsDropdown().props()).toMatchObject({
          items: deployKeysItems,
        });
      });

      it('renders a group component for each search result', () => {
        expect(findAllDeployKeyComponents().length).toBe(deployKeysItems.length);
      });

      it('emits a select event when a search result is selected', () => {
        const firstSearchResult = deployKeysItems[1];
        findSearchResultsDropdown().vm.$emit('select', firstSearchResult.id);

        expect(wrapper.emitted('select')).toMatchObject([
          [
            {
              id: firstSearchResult.id,
              title: firstSearchResult.title,
              user: firstSearchResult.user,
              type: 'deployKeys',
              text: firstSearchResult.title,
              value: firstSearchResult.id,
            },
          ],
        ]);
      });

      it('renders a deploy key component for each search result', () => {
        expect(findAllDeployKeyComponents().length).toBe(deployKeysItems.length);
      });
    });

    describe('selected items', () => {
      const selectedKey = deployKeysItems[0];
      const selectedItems = [selectedKey];
      beforeEach(() =>
        createComponent(
          { ...DEPLOY_KEYS_MOCK_PROPS, selectedItems },
          getAvailableDeployKeys,
          deployKeysQuerySuccess,
        ),
      );

      it('renders a heading with the total selected items', () => {
        expect(findTitle()).toContain('Deploy keys');
        expect(findCrudComponent().props('count')).toBe(1);
      });

      it('renders a deploy key component for each selected item', () => {
        expect(findAllDeployKeyComponents().length).toBe(selectedItems.length);
        expect(findAllDeployKeyComponents().at(0).props()).toMatchObject({
          data: selectedKey,
          canDelete: true,
        });
      });

      it('emits a delete event when a delete event is emitted from the deploy key component', () => {
        const id = '123';
        findAllDeployKeyComponents().at(0).vm.$emit('delete', id);

        expect(wrapper.emitted('delete')).toEqual([[id]]);
      });
    });
  });

  describe('Projects type', () => {
    beforeEach(() => createComponent(PROJECTS_MOCK_PROPS));

    it('renders a correct title', () => {
      expect(findTitle()).toContain('Projects');
    });

    it('renders the correct icon', () => {
      expect(findIcon().props('name')).toBe('project');
    });

    describe('searching', () => {
      const searchResponse = [
        { name: 'Project 1', id: '1' },
        { name: 'Project 2', id: '2' },
      ];
      const search = 'Project';

      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
      };

      beforeEach(() => emitSearchInput());

      it('calls query with correct variables when Search box receives an input', () => {
        expect(RestApi.getProjects).toHaveBeenCalledWith(search, { membership: false });
      });

      it('renders a dropdown for the search results', () => {
        expect(findSearchResultsDropdown().props()).toMatchObject({
          items: searchResponse,
        });
      });

      it('renders a project component for each search result', () => {
        expect(findAllProjectComponents().length).toBe(searchResponse.length);
      });
    });

    describe('selected items', () => {
      const selectedGroup = { name: 'Flightjs' };
      const selectedItems = [selectedGroup];
      beforeEach(() => createComponent({ ...GROUPS_MOCK_PROPS, selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findTitle()).toContain('Groups');
        expect(findCrudComponent().props('count')).toBe(1);
      });

      it('renders a group component for each selected item', () => {
        expect(findAllGroupComponents().length).toBe(selectedItems.length);
        expect(findAllGroupComponents().at(0).props()).toMatchObject({
          data: selectedGroup,
          canDelete: true,
        });
      });

      it('emits a delete event when a delete event is emitted from the group component', () => {
        const name = 'Flightjs';
        findAllGroupComponents().at(0).vm.$emit('delete', name);

        expect(wrapper.emitted('delete')).toEqual([[name]]);
      });
    });
  });
});

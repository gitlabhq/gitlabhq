import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import Api from '~/api';
import RestApi from '~/rest_api';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import UserItem from '~/vue_shared/components/list_selector/user_item.vue';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import ProjectItem from '~/vue_shared/components/list_selector/project_item.vue';
import DeployKeyItem from '~/vue_shared/components/list_selector/deploy_key_item.vue';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { ACCESS_LEVEL_REPORTER_INTEGER } from '~/access_level/constants';
import { USERS_RESPONSE_MOCK, GROUPS_RESPONSE_MOCK, SUBGROUPS_RESPONSE_MOCK } from './mock_data';

jest.mock('~/alert');
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

  const USERS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    groupPath: 'some/group/path',
    usersQueryOptions: { active: true },
    type: 'users',
  };

  const GROUPS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    type: 'groups',
  };

  const GROUP_ID_MOCK_PROPS = {
    projectPath: 'some/project/path',
    type: 'groups',
    groupId: 1,
    isProjectOnlyNamespace: true,
  };

  const DEPLOY_KEYS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    type: 'deployKeys',
  };

  const PROJECTS_MOCK_PROPS = {
    type: 'projects',
  };

  const groupsAutocompleteQuerySuccess = jest.fn().mockResolvedValue(GROUPS_RESPONSE_MOCK);

  const createComponent = async (props) => {
    fakeApollo = createMockApollo([[groupsAutocompleteQuery, groupsAutocompleteQuerySuccess]]);

    wrapper = mountExtended(ListSelector, {
      apolloProvider: fakeApollo,
      propsData: {
        ...props,
      },
    });

    await waitForPromises();
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findTitle = () => findCard().find('[data-testid="list-selector-title"]');
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
    jest.spyOn(Api, 'groupSubgroups').mockResolvedValue(SUBGROUPS_RESPONSE_MOCK);
  });

  describe('empty state', () => {
    beforeEach(() => createComponent(USERS_MOCK_PROPS));

    it('renders an empty placeholder', () => {
      expect(wrapper.findByText('No users have been added.').exists()).toBe(true);
    });
  });

  describe('Users type', () => {
    beforeEach(() => createComponent(USERS_MOCK_PROPS));

    it('renders a Card component', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders a correct title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toContain('Users');
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
        expect(findTitle().text()).toContain('Users');
        expect(findTitle().text()).toContain('1');
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
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toContain('Groups');
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
      const searchResponse = GROUPS_RESPONSE_MOCK.data.groups.nodes.map((group) => ({
        ...group,
        id: getIdFromGraphQLId(group.id),
      }));

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
        findSearchResultsDropdown().vm.$emit('select', firstSearchResult.name);

        expect(wrapper.emitted('select')).toEqual([
          [
            {
              __typename: 'Group',
              avatarUrl: null,
              fullName: 'Flightjs',
              id: 33,
              name: 'Flightjs',
              text: 'Flightjs',
              value: 'Flightjs',
              type: 'group',
            },
          ],
        ]);
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
        findSearchResultsDropdown().vm.$emit('select', firstSearchResult.name);

        expect(wrapper.emitted('select')).toMatchObject([
          [{ ...firstSearchResult, value: 'Flightjs' }],
        ]);
      });
    });

    describe('it calls subroups endpoint once group id is passed', () => {
      const searchResponse = SUBGROUPS_RESPONSE_MOCK.data;

      beforeEach(() => createComponent({ ...GROUP_ID_MOCK_PROPS }));

      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
        await waitForPromises();
        await waitForPromises();
      };

      beforeEach(() => emitSearchInput());

      it('calls query with correct variables when Search box receives an input', () => {
        expect(Api.groupSubgroups).toHaveBeenCalledWith(1, search);
      });

      it('renders a dropdown for the search results', () => {
        expect(findSearchResultsDropdown().props()).toMatchObject({
          items: searchResponse,
        });
      });
    });

    describe('selected items', () => {
      const selectedGroup = { name: 'Flightjs' };
      const selectedItems = [selectedGroup];
      beforeEach(() => createComponent({ ...GROUPS_MOCK_PROPS, selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findTitle().text()).toContain('Groups');
        expect(findTitle().text()).toContain('1');
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
    beforeEach(() => createComponent(DEPLOY_KEYS_MOCK_PROPS));

    it('renders a correct title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toContain('Deploy keys');
    });

    it('renders the correct icon', () => {
      expect(findIcon().props('name')).toBe('key');
    });

    describe('selected items', () => {
      const selectedKey = { title: 'MyKey', owner: 'peter', id: '123' };
      const selectedItems = [selectedKey];
      beforeEach(() => createComponent({ ...DEPLOY_KEYS_MOCK_PROPS, selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findTitle().text()).toContain('Deploy keys');
        expect(findTitle().text()).toContain('1');
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

      // TODO - add a test for the select event once we have API integration
      // https://gitlab.com/gitlab-org/gitlab/-/issues/432494
    });
  });

  describe('Projects type', () => {
    beforeEach(() => createComponent(PROJECTS_MOCK_PROPS));

    it('renders a correct title', () => {
      expect(findTitle().text()).toContain('Projects');
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
        expect(findTitle().text()).toContain('Groups');
        expect(findTitle().text()).toContain('1');
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

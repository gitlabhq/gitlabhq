import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import UserItem from '~/vue_shared/components/list_selector/user_item.vue';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import usersAutocompleteQuery from '~/graphql_shared/queries/users_autocomplete.query.graphql';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { USERS_RESPONSE_MOCK, GROUPS_RESPONSE_MOCK } from './mock_data';

Vue.use(VueApollo);

describe('List Selector spec', () => {
  let wrapper;
  let fakeApollo;

  const USERS_MOCK_PROPS = {
    title: 'Users',
    projectPath: 'some/project/path',
    type: 'users',
  };

  const GROUPS_MOCK_PROPS = {
    title: 'Groups',
    projectPath: 'some/project/path',
    type: 'groups',
  };

  const usersAutocompleteQuerySuccess = jest.fn().mockResolvedValue(USERS_RESPONSE_MOCK);
  const groupsAutocompleteQuerySuccess = jest.fn().mockResolvedValue(GROUPS_RESPONSE_MOCK);

  const createComponent = async (
    props,
    query = usersAutocompleteQuery,
    queryResponse = usersAutocompleteQuerySuccess,
  ) => {
    fakeApollo = createMockApollo([[query, queryResponse]]);

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
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllUserComponents = () => wrapper.findAllComponents(UserItem);
  const findAllGroupComponents = () => wrapper.findAllComponents(GroupItem);

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
      expect(usersAutocompleteQuerySuccess).not.toHaveBeenCalled();
      expect(findAllUserComponents().length).toBe(0);
    });

    describe('searching', () => {
      const searchResponse = USERS_RESPONSE_MOCK.data.project.autocompleteUsers;
      const search = 'foo';

      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
      };

      beforeEach(() => emitSearchInput());

      it('calls query with correct variables when Search box receives an input', () => {
        expect(usersAutocompleteQuerySuccess).toHaveBeenCalledWith({
          fullPath: USERS_MOCK_PROPS.projectPath,
          isProject: true,
          search,
        });
      });

      it('renders a List box component with the correct props', () => {
        expect(findListBox().props()).toMatchObject({ multiple: true, items: searchResponse });
      });

      it('renders a user component for each search result', () => {
        expect(findAllUserComponents().length).toBe(searchResponse.length);
      });

      it('emits an event when a search result is selected', () => {
        const firstSearchResult = searchResponse[0];
        findAllUserComponents().at(0).vm.$emit('select', firstSearchResult.username);

        expect(wrapper.emitted('select')).toEqual([
          [{ ...firstSearchResult, text: 'Administrator', value: 'root' }],
        ]);
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
    beforeEach(() =>
      createComponent(GROUPS_MOCK_PROPS, groupsAutocompleteQuery, groupsAutocompleteQuerySuccess),
    );

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

    describe('searching', () => {
      const searchResponse = GROUPS_RESPONSE_MOCK.data.groups.nodes;
      const search = 'foo';

      const emitSearchInput = async () => {
        findSearchBox().vm.$emit('input', search);
        await waitForPromises();
      };

      beforeEach(() => emitSearchInput());

      it('calls query with correct variables when Search box receives an input', () => {
        expect(groupsAutocompleteQuerySuccess).toHaveBeenCalledWith({
          search,
        });
      });

      it('renders a List box component with the correct props', () => {
        expect(findListBox().props()).toMatchObject({ multiple: true, items: searchResponse });
      });

      it('renders a group component for each search result', () => {
        expect(findAllGroupComponents().length).toBe(searchResponse.length);
      });

      it('emits an event when a search result is selected', () => {
        const firstSearchResult = searchResponse[0];
        findAllGroupComponents().at(0).vm.$emit('select', firstSearchResult.name);

        expect(wrapper.emitted('select')).toEqual([
          [{ ...firstSearchResult, text: 'Flightjs', value: 'Flightjs' }],
        ]);
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

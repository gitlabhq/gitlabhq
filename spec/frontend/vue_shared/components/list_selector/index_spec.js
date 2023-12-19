import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import Api from '~/api';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import UserItem from '~/vue_shared/components/list_selector/user_item.vue';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import DeployKeyItem from '~/vue_shared/components/list_selector/deploy_key_item.vue';
import groupsAutocompleteQuery from '~/graphql_shared/queries/groups_autocomplete.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { USERS_RESPONSE_MOCK, GROUPS_RESPONSE_MOCK } from './mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

describe('List Selector spec', () => {
  let wrapper;
  let fakeApollo;

  const USERS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    groupPath: 'some/group/path',
    type: 'users',
  };

  const GROUPS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    type: 'groups',
  };

  const DEPLOY_KEYS_MOCK_PROPS = {
    projectPath: 'some/project/path',
    type: 'deployKeys',
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
  const findNamespaceDropdown = () => findAllListBoxComponents().at(1);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllUserComponents = () => wrapper.findAllComponents(UserItem);
  const findAllGroupComponents = () => wrapper.findAllComponents(GroupItem);
  const findAllDeployKeyComponents = () => wrapper.findAllComponents(DeployKeyItem);

  beforeEach(() => {
    jest.spyOn(Api, 'projectUsers').mockResolvedValue(USERS_RESPONSE_MOCK);
    jest.spyOn(Api, 'groupMembers').mockResolvedValue({ data: USERS_RESPONSE_MOCK });
  });

  describe('Users type', () => {
    const search = 'foo';

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

    it('renders two namespace dropdown items', () => {
      expect(findNamespaceDropdown().props('items').length).toBe(2);
    });

    it('does not call query when search box has not received an input', () => {
      expect(Api.projectUsers).not.toHaveBeenCalled();
      expect(Api.groupMembers).not.toHaveBeenCalled();
      expect(findAllUserComponents().length).toBe(0);
    });

    describe.each`
      dropdownItemValue | apiMethod         | apiParams                                          | searchResponse
      ${'false'}        | ${'groupMembers'} | ${[USERS_MOCK_PROPS.groupPath, { query: search }]} | ${USERS_RESPONSE_MOCK}
      ${'true'}         | ${'projectUsers'} | ${[USERS_MOCK_PROPS.projectPath, search]}          | ${USERS_RESPONSE_MOCK}
    `(
      'searching based on namespace dropdown selection',
      ({ dropdownItemValue, apiMethod, apiParams, searchResponse }) => {
        const emitSearchInput = async () => {
          findSearchBox().vm.$emit('input', search);
          await waitForPromises();
        };

        beforeEach(async () => {
          findNamespaceDropdown().vm.$emit('select', dropdownItemValue);
          await emitSearchInput();
        });

        it('shows error alert when API fails', async () => {
          jest.spyOn(Api, apiMethod).mockRejectedValueOnce();
          await emitSearchInput();

          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred while fetching. Please try again.',
          });
        });

        it('calls query with correct variables when Search box receives an input', () => {
          expect(Api[apiMethod]).toHaveBeenCalledWith(...apiParams);
        });

        it('renders a List box component with the correct props', () => {
          expect(findSearchResultsDropdown().props()).toMatchObject({
            multiple: true,
            items: searchResponse,
          });
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
      },
    );

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

      it('renders a dropdown for the search results', () => {
        expect(findSearchResultsDropdown().props()).toMatchObject({
          multiple: true,
          items: searchResponse,
        });
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
});

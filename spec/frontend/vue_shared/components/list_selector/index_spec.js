import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCard, GlIcon, GlCollapsibleListbox, GlSearchBoxByType } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import User from '~/vue_shared/components/list_selector/user.vue';
import usersAutocompleteQuery from '~/graphql_shared/queries/users_autocomplete.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { USERS_RESPONSE_MOCK } from './mock_data';

Vue.use(VueApollo);

describe('List Selector spec', () => {
  let wrapper;
  let fakeApollo;

  const MOCK_PROPS = {
    title: 'Users',
    projectPath: 'some/project/path',
    type: 'users',
  };

  const usersAutocompleteQuerySuccess = jest.fn().mockResolvedValue(USERS_RESPONSE_MOCK);

  const createComponent = async (props) => {
    fakeApollo = createMockApollo([[usersAutocompleteQuery, usersAutocompleteQuerySuccess]]);

    wrapper = mountExtended(ListSelector, {
      apolloProvider: fakeApollo,
      propsData: {
        ...MOCK_PROPS,
        ...props,
      },
    });

    await waitForPromises();
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findTitle = () => wrapper.findByText(MOCK_PROPS.title);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllUserComponents = () => wrapper.findAllComponents(User);

  describe('Users type', () => {
    beforeEach(() => createComponent({ type: 'users' }));

    it('renders a Card component', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders a title', () => {
      expect(findTitle().exists()).toBe(true);
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
          fullPath: MOCK_PROPS.projectPath,
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
      beforeEach(() => createComponent({ selectedItems }));

      it('renders a heading with the total selected items', () => {
        expect(findCard().text()).toContain('Users');
        expect(findCard().text()).toContain('1');
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
});

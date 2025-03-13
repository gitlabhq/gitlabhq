import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlFormCheckbox } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import AjaxCache from '~/lib/utils/ajax_cache';
import AuthorFilter from '~/search/sidebar/components/author_filter/index.vue';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('Author filter', () => {
  let wrapper;
  const mock = new MockAdapter(axios);

  // Mock author data that matches the expected structure
  const mockAuthors = [
    { username: 'root', name: 'Administrator', text: 'Administrator', value: 'root' },
    { username: 'john', name: 'John Doe', text: 'John Doe', value: 'john' },
  ];

  const actions = {
    setQuery: jest.fn(),
    applyQuery: jest.fn(),
  };

  const defaultState = {
    query: {
      scope: 'merge_requests',
      group_id: 1,
      search: '*',
    },
  };

  const createComponent = (state = {}) => {
    const store = new Vuex.Store({
      state: {
        ...defaultState.state,
        ...state,
      },
      actions,
    });

    wrapper = shallowMount(AuthorFilter, {
      store,
    });
  };

  const findFilterDropdown = () => wrapper.findComponent(FilterDropdown);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  beforeEach(() => {
    // Setup default API mock
    mock.onGet(/\/-\/autocomplete\/users\.json.*/).reply(200, mockAuthors);

    createComponent();
  });

  afterEach(() => {
    mock.reset();
    actions.setQuery.mockReset();
    actions.applyQuery.mockReset();
  });

  describe.each(['not[author_username]', 'author_username'])(
    'when author is selected for %s author search',
    (authorParam) => {
      beforeEach(async () => {
        // First create the component with initial state
        createComponent({
          query: {
            ...MOCK_QUERY,
            [authorParam]: 'root',
          },
        });

        // Ensure authors data is loaded before selection
        await wrapper.vm.getCachedDropdownData();
        await nextTick();

        // Then simulate selection
        findFilterDropdown().vm.$emit('selected', 'root');
        await nextTick();
      });

      it('renders the component with selected options', () => {
        expect(findFilterDropdown().props('selectedItem')).toBe('root');
        expect(findGlFormCheckbox().attributes('checked')).toBe(
          authorParam === 'not[author_username]' ? 'true' : undefined,
        );
      });

      it('displays the correct placeholder text', () => {
        expect(findFilterDropdown().props('searchText')).toBe('Administrator');
      });
    },
  );

  describe('when opening dropdown', () => {
    beforeEach(() => {
      jest.spyOn(AjaxCache, 'retrieve').mockResolvedValue(mockAuthors);

      createComponent({
        groupInitialJson: {
          id: 1,
          full_name: 'gitlab-org/gitlab-test',
          full_path: 'gitlab-org/gitlab-test',
        },
      });
    });

    it('calls AjaxCache with correct params', async () => {
      findFilterDropdown().vm.$emit('shown');
      await nextTick();
      expect(AjaxCache.retrieve).toHaveBeenCalledWith(
        '/-/autocomplete/users.json?current_user=true&active=true&group_id=1&search=',
      );
    });

    // we are testing a UX fix https://gitlab.com/gitlab-org/gitlab/-/issues/507804
    describe('UX flow for author selection and search', () => {
      beforeEach(() => {
        mock.onGet(/\/-\/autocomplete\/users\.json.*/).reply(200, [
          { username: 'root', name: 'Administrator', text: 'Administrator', value: 'root' },
          { username: 'john', name: 'John Doe', text: 'John Doe', value: 'john' },
        ]);
      });

      it('does not change selected author name when none was selected', async () => {
        createComponent();

        expect(findFilterDropdown().props('selectedItem')).toBe('');
        findFilterDropdown().vm.$emit('shown');
        await nextTick();

        findFilterDropdown().vm.$emit('search', 'john');
        await nextTick();

        expect(findFilterDropdown().props('selectedItem')).toBe('');
      });

      it('maintains selected author while searching for others', async () => {
        createComponent();

        await wrapper.vm.getCachedDropdownData();
        await nextTick();

        findFilterDropdown().vm.$emit('selected', 'root');
        await nextTick();

        expect(findFilterDropdown().props('selectedItem')).toBe('root');
        expect(findFilterDropdown().props('searchText')).toBe('Administrator');

        findFilterDropdown().vm.$emit('shown');
        await nextTick();

        findFilterDropdown().vm.$emit('search', 'john');
        await nextTick();

        expect(findFilterDropdown().props('selectedItem')).toBe('root');
        expect(findFilterDropdown().props('searchText')).toBe('Administrator');
      });

      describe('edge cases', () => {
        it('handles search with no results', async () => {
          createComponent();

          await wrapper.vm.getCachedDropdownData();
          await nextTick();

          findFilterDropdown().vm.$emit('selected', 'root');
          await nextTick();

          findFilterDropdown().vm.$emit('search', 'nonexistent');
          await nextTick();

          expect(findFilterDropdown().props('selectedItem')).toBe('root');
          expect(findFilterDropdown().props('searchText')).toBe('Administrator');
        });

        it('handles multiple searches without changing selection', async () => {
          createComponent();

          await wrapper.vm.getCachedDropdownData();
          await nextTick();

          findFilterDropdown().vm.$emit('selected', 'root');
          await nextTick();

          const searches = ['john', 'admin', 'test'];
          for (const searchTerm of searches) {
            findFilterDropdown().vm.$emit('search', searchTerm);
            nextTick(() => {
              expect(findFilterDropdown().props('selectedItem')).toBe('root');
              expect(findFilterDropdown().props('searchText')).toBe('Administrator');
            });
          }
        });
      });
    });
  });

  describe.each([false, true])('when selecting an author with %s', (toggle) => {
    beforeEach(() => {
      createComponent({
        query: {
          ...MOCK_QUERY,
        },
      });
    });

    it('calls setQuery with the correct params', () => {
      const authorParam = 'author_username';
      const authorNotParam = 'not[author_username]';

      wrapper.vm.toggleState = !toggle;
      findFilterDropdown().vm.$emit('selected', 'root');

      expect(actions.setQuery).toHaveBeenCalledTimes(2);
      expect(actions.setQuery.mock.calls).toMatchObject([
        [
          expect.anything(),
          {
            key: toggle ? authorParam : authorNotParam,
            value: 'root',
          },
        ],
        [
          expect.anything(),
          {
            key: toggle ? authorNotParam : authorParam,
            value: '',
          },
        ],
      ]);
    });
  });

  describe('when resetting selected author', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`calls setQuery with correct param`, () => {
      findFilterDropdown().vm.$emit('reset');

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'author_username',
        value: '',
      });

      expect(actions.setQuery).toHaveBeenCalledWith(expect.anything(), {
        key: 'not[author_username]',
        value: '',
      });

      expect(actions.applyQuery).toHaveBeenCalled();
    });
  });
});

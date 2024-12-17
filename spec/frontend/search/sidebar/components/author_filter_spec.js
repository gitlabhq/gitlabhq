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
import { MOCK_QUERY, mockAuthorsAxiosResponse } from '../../mock_data';

Vue.use(Vuex);

describe('Author filter', () => {
  let wrapper;
  const mock = new MockAdapter(axios);

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

  const createComponent = (state) => {
    const store = new Vuex.Store({
      ...defaultState,
      state,
      actions,
    });

    wrapper = shallowMount(AuthorFilter, {
      store,
    });
  };

  const findFilterDropdown = () => wrapper.findComponent(FilterDropdown);
  const findGlFormCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  beforeEach(() => {
    createComponent();
  });

  describe('when initial state', () => {
    it('renders the component', () => {
      expect(findFilterDropdown().exists()).toBe(true);
      expect(findGlFormCheckbox().exists()).toBe(true);
    });
  });

  describe.each(['not[author_username]', 'author_username'])(
    `when author is selected for %s author search`,
    (authorParam) => {
      beforeEach(async () => {
        mock
          .onGet('/-/autocomplete/users.json?current_user=true&active=true&search=')
          .reply(200, mockAuthorsAxiosResponse);
        createComponent({
          query: {
            ...MOCK_QUERY,
            [authorParam]: 'root',
          },
        });

        findFilterDropdown().vm.$emit('selected', 'root');
        await nextTick();
      });

      it('renders the component with selected options', () => {
        expect(findFilterDropdown().props('selectedItem')).toBe('root');
        expect(findGlFormCheckbox().attributes('checked')).toBe(
          authorParam === 'not[author_username]' ? 'true' : undefined,
        );
      });

      it('displays the correct placeholder text and icon', () => {
        expect(findFilterDropdown().props('searchText')).toBe('Administrator');
        expect(findFilterDropdown().props('icon')).toBe('user');
      });
    },
  );

  describe('when opening dropdown', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
      jest.spyOn(AjaxCache, 'retrieve');

      createComponent({
        groupInitialJson: {
          id: 1,
          full_name: 'gitlab-org/gitlab-test',
          full_path: 'gitlab-org/gitlab-test',
        },
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls AjaxCache with correct params', () => {
      findFilterDropdown().vm.$emit('shown');
      expect(AjaxCache.retrieve).toHaveBeenCalledWith(
        '/-/autocomplete/users.json?current_user=true&active=true&group_id=1&search=',
      );
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

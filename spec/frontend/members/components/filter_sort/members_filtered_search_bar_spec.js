import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import setWindowLocation from 'helpers/set_window_location_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import {
  MEMBERS_TAB_TYPES,
  FILTERED_SEARCH_TOKEN_TWO_FACTOR,
  FILTERED_SEARCH_TOKEN_WITH_INHERITED_PERMISSIONS,
  FILTERED_SEARCH_MAX_ROLE,
} from '~/members/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

jest.mock('~/lib/utils/url_utility', () => {
  const urlUtility = jest.requireActual('~/lib/utils/url_utility');

  return {
    __esModule: true,
    ...urlUtility,
    visitUrl: jest.fn(),
  };
});

Vue.use(Vuex);

describe('MembersFilteredSearchBar', () => {
  let wrapper;

  const createComponent = ({ state = {}, provide = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: {
          namespaced: true,
          state: {
            filteredSearchBar: {
              show: true,
              tokens: [FILTERED_SEARCH_TOKEN_TWO_FACTOR.type, FILTERED_SEARCH_MAX_ROLE.type],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
            ...state,
          },
        },
      },
    });

    wrapper = shallowMount(MembersFilteredSearchBar, {
      provide: {
        sourceId: 1,
        canManageMembers: true,
        namespace: MEMBERS_TAB_TYPES.user,
        availableRoles: [],
        ...provide,
      },
      store,
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  it('passes correct props to `FilteredSearchBar` component', () => {
    createComponent();

    expect(findFilteredSearchBar().props()).toMatchObject({
      namespace: '1',
      recentSearchesStorageKey: 'group_members',
      searchInputPlaceholder: 'Filter members',
    });
  });

  describe('filtering tokens', () => {
    it('includes tokens set in `filteredSearchBar.tokens`', () => {
      createComponent();

      expect(findFilteredSearchBar().props('tokens')).toEqual([
        FILTERED_SEARCH_TOKEN_TWO_FACTOR,
        FILTERED_SEARCH_MAX_ROLE,
      ]);
    });

    it('sets the provided `availableRoles` as options to the `max_role` token', () => {
      const availableRoles = { title: 'Guest', value: 'static-10' };

      createComponent({ provide: { availableRoles } });

      const maxRoleToken = findFilteredSearchBar()
        .props('tokens')
        .find((token) => token.type === FILTERED_SEARCH_MAX_ROLE.type);

      expect(maxRoleToken.options).toEqual(availableRoles);
    });

    describe('when `canManageMembers` is false', () => {
      it('excludes 2FA token', () => {
        createComponent({
          state: {
            filteredSearchBar: {
              show: true,
              tokens: [
                FILTERED_SEARCH_TOKEN_TWO_FACTOR.type,
                FILTERED_SEARCH_TOKEN_WITH_INHERITED_PERMISSIONS.type,
              ],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
          },
          provide: {
            canManageMembers: false,
          },
        });

        expect(findFilteredSearchBar().props('tokens')).not.toContain(
          FILTERED_SEARCH_TOKEN_TWO_FACTOR,
        );
      });
    });
  });

  describe('when filters are set via query params', () => {
    beforeEach(() => {
      setWindowLocation('https://localhost');
    });

    it('parses and passes tokens to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      setWindowLocation('?two_factor=enabled&token_not_available=foobar');

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: FILTERED_SEARCH_TOKEN_TWO_FACTOR.type,
          value: {
            data: 'enabled',
            operator: '=',
          },
        },
      ]);
    });

    it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      setWindowLocation('?search=foobar');

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: FILTERED_SEARCH_TERM,
          value: {
            data: 'foobar',
          },
        },
      ]);
    });

    it('parses and passes search param with multiple words to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      setWindowLocation('?search=foo+bar+baz');

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: FILTERED_SEARCH_TERM,
          value: {
            data: 'foo bar baz',
          },
        },
      ]);
    });
  });

  describe('when filter bar is submitted', () => {
    beforeEach(() => {
      setWindowLocation('https://localhost');
    });

    it('adds correct filter query params', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_TWO_FACTOR.type, value: { data: 'enabled', operator: '=' } },
      ]);

      expect(visitUrl).toHaveBeenCalledWith('https://localhost/?two_factor=enabled');
    });

    it('adds search query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_TWO_FACTOR.type, value: { data: 'enabled', operator: '=' } },
        { type: FILTERED_SEARCH_TERM, value: { data: 'foobar' } },
      ]);

      expect(visitUrl).toHaveBeenCalledWith('https://localhost/?two_factor=enabled&search=foobar');
    });

    it('adds search query param with multiple words', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_TWO_FACTOR.type, value: { data: 'enabled', operator: '=' } },
        { type: FILTERED_SEARCH_TERM, value: { data: 'foo bar baz' } },
      ]);

      expect(visitUrl).toHaveBeenCalledWith(
        'https://localhost/?two_factor=enabled&search=foo+bar+baz',
      );
    });

    it('adds sort query param', () => {
      setWindowLocation('?sort=name_asc');

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TOKEN_TWO_FACTOR.type, value: { data: 'enabled', operator: '=' } },
        { type: FILTERED_SEARCH_TERM, value: { data: 'foobar' } },
      ]);

      expect(visitUrl).toHaveBeenCalledWith(
        'https://localhost/?two_factor=enabled&search=foobar&sort=name_asc',
      );
    });

    it('adds active tab query param', () => {
      setWindowLocation('?tab=invited');

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: FILTERED_SEARCH_TERM, value: { data: 'foobar' } },
      ]);

      expect(visitUrl).toHaveBeenCalledWith('https://localhost/?search=foobar&tab=invited');
    });
  });
});

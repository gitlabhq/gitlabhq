import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MembersFilteredSearchBar', () => {
  let wrapper;

  const createComponent = ({ state = {}, provide = {} } = {}) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            filteredSearchBar: {
              show: true,
              tokens: ['two_factor'],
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
      localVue,
      provide: {
        sourceId: 1,
        canManageMembers: true,
        namespace: MEMBER_TYPES.user,
        ...provide,
      },
      store,
    });
  };

  const findFilteredSearchBar = () => wrapper.find(FilteredSearchBar);

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
        {
          type: 'two_factor',
          icon: 'lock',
          title: '2FA',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATOR_IS_ONLY,
          options: [
            { value: 'enabled', title: 'Enabled' },
            { value: 'disabled', title: 'Disabled' },
          ],
          requiredPermissions: 'canManageMembers',
        },
      ]);
    });

    describe('when `canManageMembers` is false', () => {
      it('excludes 2FA token', () => {
        createComponent({
          state: {
            filteredSearchBar: {
              show: true,
              tokens: ['two_factor', 'with_inherited_permissions'],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
          },
          provide: {
            canManageMembers: false,
          },
        });

        expect(findFilteredSearchBar().props('tokens')).toEqual([
          {
            type: 'with_inherited_permissions',
            icon: 'group',
            title: 'Membership',
            token: GlFilteredSearchToken,
            unique: true,
            operators: OPERATOR_IS_ONLY,
            options: [
              { value: 'exclude', title: 'Direct' },
              { value: 'only', title: 'Inherited' },
            ],
          },
        ]);
      });
    });
  });

  describe('when filters are set via query params', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL('https://localhost');
    });

    it('parses and passes tokens to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      window.location.search = '?two_factor=enabled&token_not_available=foobar';

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: 'two_factor',
          value: {
            data: 'enabled',
            operator: '=',
          },
        },
      ]);
    });

    it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      window.location.search = '?search=foobar';

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: 'filtered-search-term',
          value: {
            data: 'foobar',
          },
        },
      ]);
    });

    it('parses and passes search param with multiple words to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      window.location.search = '?search=foo+bar+baz';

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: 'filtered-search-term',
          value: {
            data: 'foo bar baz',
          },
        },
      ]);
    });
  });

  describe('when filter bar is submitted', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL('https://localhost');
    });

    it('adds correct filter query params', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?two_factor=enabled');
    });

    it('adds search query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
        { type: 'filtered-search-term', value: { data: 'foobar' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?two_factor=enabled&search=foobar');
    });

    it('adds search query param with multiple words', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
        { type: 'filtered-search-term', value: { data: 'foo bar baz' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?two_factor=enabled&search=foo+bar+baz');
    });

    it('adds sort query param', () => {
      window.location.search = '?sort=name_asc';

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
        { type: 'filtered-search-term', value: { data: 'foobar' } },
      ]);

      expect(window.location.href).toBe(
        'https://localhost/?two_factor=enabled&search=foobar&sort=name_asc',
      );
    });

    it('adds active tab query param', () => {
      window.location.search = '?tab=invited';

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'filtered-search-term', value: { data: 'foobar' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?search=foobar&tab=invited');
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import SortDropdown from '~/members/components/filter_sort/sort_dropdown.vue';
import { MEMBERS_TAB_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('FilterSortContainer', () => {
  let wrapper;

  const createComponent = (state) => {
    const store = new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: {
          namespaced: true,
          state: {
            filteredSearchBar: {
              show: true,
              tokens: ['two_factor'],
              searchParam: 'search',
              placeholder: 'Filter members',
              recentSearchesStorageKey: 'group_members',
            },
            tableSortableFields: ['account'],
            ...state,
          },
        },
      },
    });

    wrapper = shallowMount(FilterSortContainer, {
      store,
      provide: {
        namespace: MEMBERS_TAB_TYPES.user,
      },
    });
  };

  describe('when `filteredSearchBar.show` is `false` and `tableSortableFields` is empty', () => {
    it('renders nothing', () => {
      createComponent({
        filteredSearchBar: {
          show: false,
        },
        tableSortableFields: [],
      });

      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe('when `filteredSearchBar.show` is `true`', () => {
    it('renders `MembersFilteredSearchBar`', () => {
      createComponent({
        filteredSearchBar: {
          show: true,
        },
      });

      expect(wrapper.findComponent(MembersFilteredSearchBar).exists()).toBe(true);
    });
  });

  describe('when `tableSortableFields` is set', () => {
    it('renders `SortDropdown`', () => {
      createComponent({
        tableSortableFields: ['account'],
      });

      expect(wrapper.findComponent(SortDropdown).exists()).toBe(true);
    });
  });
});

import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import SortDropdown from '~/members/components/filter_sort/sort_dropdown.vue';
import { MEMBER_TYPES } from '~/members/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('FilterSortContainer', () => {
  let wrapper;

  const createComponent = (state) => {
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
            tableSortableFields: ['account'],
            ...state,
          },
        },
      },
    });

    wrapper = shallowMount(FilterSortContainer, {
      localVue,
      store,
      provide: {
        namespace: MEMBER_TYPES.user,
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

      expect(wrapper.html()).toBe('');
    });
  });

  describe('when `filteredSearchBar.show` is `true`', () => {
    it('renders `MembersFilteredSearchBar`', () => {
      createComponent({
        filteredSearchBar: {
          show: true,
        },
      });

      expect(wrapper.find(MembersFilteredSearchBar).exists()).toBe(true);
    });
  });

  describe('when `tableSortableFields` is set', () => {
    it('renders `SortDropdown`', () => {
      createComponent({
        tableSortableFields: ['account'],
      });

      expect(wrapper.find(SortDropdown).exists()).toBe(true);
    });
  });
});

import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('FilterSortContainer', () => {
  let wrapper;

  const createComponent = state => {
    const store = new Vuex.Store({
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
    });

    wrapper = shallowMount(FilterSortContainer, {
      localVue,
      store,
    });
  };

  describe('when `filteredSearchBar.show` is `false`', () => {
    it('renders nothing', () => {
      createComponent({
        filteredSearchBar: {
          show: false,
        },
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
});

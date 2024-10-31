import Vue from 'vue';
import FilteredSearchAndSort from './components/filtered_search_and_sort.vue';

export const initAdminGroupsFilteredSearchAndSort = () => {
  const el = document.getElementById('js-admin-groups-filtered-search-and-sort');

  if (!el) return false;

  return new Vue({
    el,
    name: 'AdminGroupsFilteredSearchAndSort',
    render(createElement) {
      return createElement(FilteredSearchAndSort);
    },
  });
};

import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import FilteredSearchAndSort from './components/filtered_search_and_sort.vue';

export const initProjectsFilteredSearchAndSort = ({ sortEventName, filterEventName } = {}) => {
  const el = document.getElementById('js-projects-filtered-search-and-sort');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, programmingLanguages, pathsToExcludeSortOn } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
  );

  return new Vue({
    el,
    name: 'ProjectsFilteredSearchAndSortRoot',
    provide: {
      initialSort,
      programmingLanguages,
      pathsToExcludeSortOn,
      sortEventName,
      filterEventName,
    },
    render(createElement) {
      return createElement(FilteredSearchAndSort);
    },
  });
};

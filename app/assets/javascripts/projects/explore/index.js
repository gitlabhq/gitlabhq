import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import FilteredSearchAndSort from './components/filtered_search_and_sort.vue';

export const initProjectsExploreFilteredSearchAndSort = () => {
  const el = document.getElementById('js-projects-explore-filtered-search-and-sort');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialSort, programmingLanguages, starredExploreProjectsPath, exploreRootPath } =
    convertObjectPropsToCamelCase(JSON.parse(appData));

  return new Vue({
    el,
    name: 'ProjectsExploreFilteredSearchAndSortRoot',
    provide: { initialSort, programmingLanguages, starredExploreProjectsPath, exploreRootPath },
    render(createElement) {
      return createElement(FilteredSearchAndSort);
    },
  });
};

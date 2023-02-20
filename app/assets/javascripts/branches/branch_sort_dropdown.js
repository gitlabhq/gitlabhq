import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import SortDropdown from './components/sort_dropdown.vue';

const mountDropdownApp = (el) => {
  const { projectBranchesFilteredPath, sortOptions, showDropdown, sortedBy } = el.dataset;

  return new Vue({
    el,
    name: 'SortBranchesDropdownApp',
    components: {
      SortDropdown,
    },
    provide: {
      projectBranchesFilteredPath,
      sortOptions: JSON.parse(sortOptions),
      showDropdown: parseBoolean(showDropdown),
      sortedBy,
    },
    render: (createElement) => createElement(SortDropdown),
  });
};

export default () => {
  const el = document.getElementById('js-branches-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

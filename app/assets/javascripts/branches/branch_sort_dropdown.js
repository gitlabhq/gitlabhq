import Vue from 'vue';
import SortDropdown from './components/sort_dropdown.vue';

const mountDropdownApp = (el) => {
  const { mode, projectBranchesFilteredPath, sortOptions } = el.dataset;

  return new Vue({
    el,
    name: 'SortBranchesDropdownApp',
    components: {
      SortDropdown,
    },
    provide: {
      mode,
      projectBranchesFilteredPath,
      sortOptions: JSON.parse(sortOptions),
    },
    render: (createElement) => createElement(SortDropdown),
  });
};

export default () => {
  const el = document.getElementById('js-branches-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

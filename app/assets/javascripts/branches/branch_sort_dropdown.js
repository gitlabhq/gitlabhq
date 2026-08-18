import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import SortDropdown from './components/sort_dropdown.vue';

const mountDropdownApp = (el) => {
  const { projectBranchesFilteredPath, sortOptions, showDropdown, sortedBy } = el.dataset;

  return initVueApp({
    el,
    name: 'SortBranchesDropdownApp',
    provide: {
      projectBranchesFilteredPath,
      sortOptions: JSON.parse(sortOptions),
      showDropdown: parseBoolean(showDropdown),
      sortedBy,
    },
    component: SortDropdown,
  });
};

export default () => {
  const el = document.getElementById('js-branches-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

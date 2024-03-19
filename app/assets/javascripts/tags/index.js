import Vue from 'vue';
import initSourceCodeDropdowns from '~/vue_shared/components/download_dropdown/init_download_dropdowns';
import SortDropdown from './components/sort_dropdown.vue';

const mountDropdownApp = (el) => {
  const { sortOptions, filterTagsPath } = el.dataset;

  return new Vue({
    el,
    name: 'SortTagsDropdownApp',
    components: {
      SortDropdown,
    },
    provide: {
      sortOptions: JSON.parse(sortOptions),
      filterTagsPath,
    },
    render: (createElement) => createElement(SortDropdown),
  });
};

initSourceCodeDropdowns();

export default () => {
  const el = document.getElementById('js-tags-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

import Vue from 'vue';
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

export default () => {
  const el = document.getElementById('js-tags-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

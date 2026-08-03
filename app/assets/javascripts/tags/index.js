import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import initSourceCodeDropdowns from '~/vue_shared/components/download_dropdown/init_download_dropdowns';
import SortDropdown from './components/sort_dropdown.vue';

const mountDropdownApp = (el) => {
  const { filterTagsPath } = el.dataset;

  return initVueApp({
    el,
    name: 'SortTagsDropdownApp',
    provide: {
      filterTagsPath,
    },
    component: SortDropdown,
  });
};

initSourceCodeDropdowns();

export default () => {
  const el = document.getElementById('js-tags-sort-dropdown');
  return el ? mountDropdownApp(el) : null;
};

import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CredentialsFilterSortApp from './components/credentials_filter_sort_app.vue';

export const initCredentialsFilterSortApp = () => {
  return initVueApp({
    el: document.querySelector('#js-credentials-filter-sort-app'),
    name: 'CredentialsFilterSortAppRoot',
    component: CredentialsFilterSortApp,
  });
};

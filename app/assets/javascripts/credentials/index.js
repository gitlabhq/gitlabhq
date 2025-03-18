import Vue from 'vue';
import CredentialsFilterSortApp from './components/credentials_filter_sort_app.vue';

export const initCredentialsFilterSortApp = () => {
  return new Vue({
    el: document.querySelector('#js-credentials-filter-sort-app'),
    render: (createElement) => createElement(CredentialsFilterSortApp),
  });
};

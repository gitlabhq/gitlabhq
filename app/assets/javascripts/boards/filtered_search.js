import Vue from 'vue';
import store from '~/boards/stores';
import { queryToObject } from '~/lib/utils/url_utility';
import FilteredSearch from './components/filtered_search.vue';

export default () => {
  const queryParams = queryToObject(window.location.search);
  const el = document.getElementById('js-board-filtered-search');

  /*
    When https://github.com/vuejs/vue-apollo/pull/1153 is merged and deployed
    we can remove apolloProvider option from here. Currently without it its causing
    an error
  */

  return new Vue({
    el,
    store,
    apolloProvider: {},
    render: (createElement) =>
      createElement(FilteredSearch, {
        props: { search: queryParams.search },
      }),
  });
};

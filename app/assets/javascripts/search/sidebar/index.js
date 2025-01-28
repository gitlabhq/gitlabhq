import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/graphql_shared/issuable_client';
import Translate from '~/vue_shared/translate';
import GlobalSearchSidebar from './components/app.vue';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
});

export const initSidebar = (store) => {
  const el = document.getElementById('js-search-sidebar');

  if (!el) return false;

  return new Vue({
    el,
    name: 'GlobalSearchSidebar',
    store,
    apolloProvider,
    render(createElement) {
      return createElement(GlobalSearchSidebar);
    },
  });
};

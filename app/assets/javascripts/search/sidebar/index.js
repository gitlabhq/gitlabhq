import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'GlobalSearchSidebar',
    store,
    apolloProvider,
    component: GlobalSearchSidebar,
  });
};

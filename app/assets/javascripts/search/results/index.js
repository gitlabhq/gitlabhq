import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/graphql_shared/issuable_client';
import GlobalSearchResults from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
});

export const initZoektBlobResult = (store) => {
  const el = document.getElementById('js-search-zoekt-blob-results');
  if (!el) return false;

  return new Vue({
    el,
    name: 'GlobalSearchResults',
    store,
    apolloProvider,
    render(createElement) {
      return createElement(GlobalSearchResults);
    },
  });
};

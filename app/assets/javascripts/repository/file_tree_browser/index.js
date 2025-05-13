import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { pinia } from '~/pinia/instance';
import FileBrowser from './file_tree_browser.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default async function initBrowserComponent(router) {
  const el = document.getElementById('js-file-browser');
  if (!el) return false;

  return new Vue({
    el,
    pinia,
    router,
    apolloProvider,
    render(h) {
      return h(FileBrowser);
    },
  });
}

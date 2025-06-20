import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { pinia } from '~/pinia/instance';
import FileBrowser from './file_tree_browser.vue';

Vue.use(VueApollo);

export default async function initBrowserComponent(router, options, apolloProvider) {
  const el = document.getElementById('js-file-browser');
  if (!el) return false;

  const { projectPath, ref, refType } = options;
  return new Vue({
    el,
    pinia,
    router,
    apolloProvider,
    provide: { apolloProvider },
    render(h) {
      return h(FileBrowser, { props: { projectPath, currentRef: ref, refType } });
    },
  });
}

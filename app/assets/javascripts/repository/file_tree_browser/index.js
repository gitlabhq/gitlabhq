import Vue from 'vue';
import apolloProvider from '~/repository/graphql';
import { pinia } from '~/pinia/instance';
import FileTreeBrowser from './file_tree_browser.vue';

export default async function initFileTreeBrowser(router, options) {
  const el = document.getElementById('js-file-browser');
  if (!el) return false;

  const { projectPath, ref, refType } = options;
  return new Vue({
    el,
    name: 'FileTreeBrowserRoot',
    pinia,
    router,
    apolloProvider,
    provide: { apolloProvider },
    computed: {
      visible() {
        const isProjectOverview = this.$route?.name === 'projectRoot';
        return !isProjectOverview;
      },
    },
    render(h) {
      if (!this.visible) return null;

      return h(FileTreeBrowser, {
        props: {
          projectPath,
          currentRef: ref,
          refType,
        },
      });
    },
  });
}

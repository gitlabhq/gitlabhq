import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { pinia } from '~/pinia/instance';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import { useViewport } from '~/pinia/global_stores/viewport';
import FileTreeBrowser from './file_tree_browser.vue';

Vue.use(VueApollo);

export default async function initFileTreeBrowser(router, options, apolloProvider) {
  const el = document.getElementById('js-file-browser');
  if (!el) return false;

  const { projectPath, ref, refType } = options;
  return new Vue({
    el,
    pinia,
    router,
    apolloProvider,
    provide: { apolloProvider },
    computed: {
      visible() {
        const isProjectOverview = this.$route?.name === 'projectRoot';
        return (
          !isProjectOverview &&
          !useViewport().isCompactViewport &&
          useFileTreeBrowserVisibility().fileTreeBrowserVisible
        );
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

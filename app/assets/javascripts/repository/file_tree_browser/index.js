import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { pinia } from '~/pinia/instance';
import { useMainContainer } from '~/pinia/global_stores/main_container';
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
        return !isProjectOverview && !useMainContainer().isCompact;
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

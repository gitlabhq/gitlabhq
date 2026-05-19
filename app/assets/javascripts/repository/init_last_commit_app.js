import Vue from 'vue';
import apolloProvider from '~/repository/graphql';
import LastCommit from '~/repository/components/last_commit.vue';
import { generateHistoryUrl } from '~/repository/utils/url_utility';

export default function initLastCommitApp(router) {
  const lastCommitEl = document.getElementById('js-last-commit');
  if (!lastCommitEl) return null;

  return new Vue({
    el: lastCommitEl,
    name: 'BlobLastCommitRoot',
    router,
    apolloProvider,
    computed: {
      currentPath() {
        return this.$route.params.path;
      },
      refType() {
        return this.$route.meta.refType || this.$route.query.ref_type;
      },
      historyUrl() {
        return generateHistoryUrl(lastCommitEl.dataset.historyLink, this.currentPath, this.refType);
      },
    },
    render(h) {
      return h(LastCommit, {
        props: {
          currentPath: this.currentPath,
          refType: this.refType,
          historyUrl: this.historyUrl.href,
        },
      });
    },
  });
}

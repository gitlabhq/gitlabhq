import Vue from 'vue';
import LastCommit from '~/repository/components/last_commit.vue';
import { generateHistoryUrl } from '~/repository/utils/url_utility';

export default function initLastCommitApp(router, apolloProvider) {
  const lastCommitEl = document.getElementById('js-last-commit');
  if (!lastCommitEl) return null;

  return new Vue({
    el: lastCommitEl,
    name: 'BlobLastCommitRoot',
    router,
    apolloProvider,
    render(h) {
      const historyUrl = generateHistoryUrl(
        lastCommitEl.dataset.historyLink,
        this.$route.params.path,
        this.$route.meta.refType || this.$route.query.ref_type,
      );
      return h(LastCommit, {
        props: {
          currentPath: this.$route.params.path,
          refType: this.$route.meta.refType || this.$route.query.ref_type,
          historyUrl: historyUrl.href,
        },
      });
    },
  });
}

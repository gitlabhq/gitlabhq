import Vue from 'vue';
import apolloProvider from '~/repository/graphql';
import LastCommit from '~/repository/components/last_commit.vue';
import repositoryPathMixin from '~/repository/mixins/repository_path';
import { generateHistoryUrl } from '~/repository/utils/url_utility';

export default function initLastCommitApp(router) {
  const lastCommitEl = document.getElementById('js-last-commit');
  if (!lastCommitEl) return null;

  return new Vue({
    el: lastCommitEl,
    name: 'LastCommitRoot',
    router,
    apolloProvider,
    mixins: [repositoryPathMixin],
    computed: {
      refType() {
        return this.$route.meta.refType || this.$route.query.ref_type;
      },
      historyUrl() {
        return generateHistoryUrl(
          lastCommitEl.dataset.historyLink,
          this.computedPath,
          this.refType,
        );
      },
    },
    render(h) {
      return h(LastCommit, {
        props: {
          currentPath: this.computedPath,
          refType: this.refType,
          historyUrl: this.historyUrl.href,
        },
      });
    },
  });
}

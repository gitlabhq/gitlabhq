import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import CommitWidget from '~/diffs/components/commit_widget.vue';

export function initCommitWidget(el) {
  const versionsStore = useMergeRequestVersions(pinia);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CommitWidgetRoot',
    render(h) {
      if (!versionsStore.commit) return null;
      return h(CommitWidget, { props: { commit: versionsStore.commit, collapsible: false } });
    },
  });
}

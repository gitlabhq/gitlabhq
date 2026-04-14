import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ForkInfo from '~/repository/components/fork_info.vue';

export default function initForkInfoApp(apolloProvider) {
  const forkEl = document.getElementById('js-fork-info');
  if (!forkEl) return null;

  const {
    projectPath,
    selectedBranch,
    sourceName,
    sourcePath,
    sourceDefaultBranch,
    canSyncBranch,
    aheadComparePath,
    behindComparePath,
    createMrPath,
    viewMrPath,
  } = forkEl.dataset;

  return new Vue({
    el: forkEl,
    name: 'BlobForkInfoRoot',
    apolloProvider,
    render(h) {
      return h(ForkInfo, {
        props: {
          canSyncBranch: parseBoolean(canSyncBranch),
          projectPath,
          selectedBranch,
          sourceName,
          sourcePath,
          sourceDefaultBranch,
          aheadComparePath,
          behindComparePath,
          createMrPath,
          viewMrPath,
        },
      });
    },
  });
}

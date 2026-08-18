import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '~/lib/utils/common_utils';
import apolloProvider from '~/repository/graphql';
import ForkInfo from '~/repository/components/fork_info.vue';

export default function initForkInfoApp() {
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

  return initVueApp({
    el: forkEl,
    name: 'BlobForkInfoRoot',
    apolloProvider,
    component: ForkInfo,
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
}

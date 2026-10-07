import { parseBoolean } from '@gitlab/frontend-utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    name: 'ForkInfoRoot',
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

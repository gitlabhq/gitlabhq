import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { initIssuableSidebar } from '~/issuable';
import { pinia } from '~/pinia/instance';
import MergeConflictsResolverApp from './merge_conflict_resolver_app.vue';
import { useMergeConflicts } from './store';

export default function initMergeConflicts() {
  const conflictsEl = document.querySelector('#conflicts');
  if (!conflictsEl) return null;

  const { sourceBranchPath, mergeRequestPath, conflictsPath, resolveConflictsPath } =
    conflictsEl.dataset;

  initIssuableSidebar();

  useMergeConflicts(pinia).fetchConflictsData(conflictsPath);

  return initVueApp({
    el: conflictsEl,
    name: 'MergeConflictsResolverAppRoot',
    pinia,
    provide: {
      sourceBranchPath,
      mergeRequestPath,
      resolveConflictsPath,
    },
    component: MergeConflictsResolverApp,
  });
}

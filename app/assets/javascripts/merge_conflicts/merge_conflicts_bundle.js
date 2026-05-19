import Vue from 'vue';
import { initIssuableSidebar } from '~/issuable';
import { pinia } from '~/pinia/instance';
import MergeConflictsResolverApp from './merge_conflict_resolver_app.vue';
import { useMergeConflicts } from './store';

export default function initMergeConflicts() {
  const conflictsEl = document.querySelector('#conflicts');

  const { sourceBranchPath, mergeRequestPath, conflictsPath, resolveConflictsPath } =
    conflictsEl.dataset;

  initIssuableSidebar();

  useMergeConflicts(pinia).fetchConflictsData(conflictsPath);

  return new Vue({
    el: conflictsEl,
    name: 'MergeConflictsResolverAppRoot',
    pinia,
    provide: {
      sourceBranchPath,
      mergeRequestPath,
      resolveConflictsPath,
    },
    render(createElement) {
      return createElement(MergeConflictsResolverApp);
    },
  });
}

import Vue from 'vue';
import initIssuableSidebar from '../init_issuable_sidebar';
import MergeConflictsResolverApp from './merge_conflict_resolver_app.vue';
import { createStore } from './store';

export default function initMergeConflicts() {
  const conflictsEl = document.querySelector('#conflicts');

  const {
    sourceBranchPath,
    mergeRequestPath,
    conflictsPath,
    resolveConflictsPath,
  } = conflictsEl.dataset;

  initIssuableSidebar();

  const store = createStore();

  return new Vue({
    el: conflictsEl,
    store,
    provide: {
      sourceBranchPath,
      mergeRequestPath,
      resolveConflictsPath,
    },
    created() {
      store.dispatch('fetchConflictsData', conflictsPath);
    },
    render(createElement) {
      return createElement(MergeConflictsResolverApp);
    },
  });
}

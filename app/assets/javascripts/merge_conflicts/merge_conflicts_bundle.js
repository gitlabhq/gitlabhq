import $ from 'jquery';
import Vue from 'vue';
import { __ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '../flash';
import initIssuableSidebar from '../init_issuable_sidebar';
import './merge_conflict_store';
import syntaxHighlight from '../syntax_highlight';
import MergeConflictsResolverApp from './merge_conflict_resolver_app.vue';
import MergeConflictsService from './merge_conflict_service';

export default function initMergeConflicts() {
  const INTERACTIVE_RESOLVE_MODE = 'interactive';
  const conflictsEl = document.querySelector('#conflicts');
  const { mergeConflictsStore } = gl.mergeConflicts;
  const mergeConflictsService = new MergeConflictsService({
    conflictsPath: conflictsEl.dataset.conflictsPath,
    resolveConflictsPath: conflictsEl.dataset.resolveConflictsPath,
  });

  const { sourceBranchPath, mergeRequestPath } = conflictsEl.dataset;

  initIssuableSidebar();

  return new Vue({
    el: conflictsEl,
    provide: {
      sourceBranchPath,
      mergeRequestPath,
    },
    data: mergeConflictsStore.state,
    computed: {
      conflictsCountText() {
        return mergeConflictsStore.getConflictsCountText();
      },
      readyToCommit() {
        return mergeConflictsStore.isReadyToCommit();
      },
      commitButtonText() {
        return mergeConflictsStore.getCommitButtonText();
      },
      showDiffViewTypeSwitcher() {
        return mergeConflictsStore.fileTextTypePresent();
      },
    },
    created() {
      mergeConflictsService
        .fetchConflictsData()
        .then(({ data }) => {
          if (data.type === 'error') {
            mergeConflictsStore.setFailedRequest(data.message);
          } else {
            mergeConflictsStore.setConflictsData(data);
          }

          mergeConflictsStore.setLoadingState(false);

          this.$nextTick(() => {
            syntaxHighlight($('.js-syntax-highlight'));
          });
        })
        .catch(() => {
          mergeConflictsStore.setLoadingState(false);
          mergeConflictsStore.setFailedRequest();
        });
    },
    methods: {
      handleViewTypeChange(viewType) {
        mergeConflictsStore.setViewType(viewType);
      },
      onClickResolveModeButton(file, mode) {
        if (mode === INTERACTIVE_RESOLVE_MODE && file.resolveEditChanged) {
          mergeConflictsStore.setPromptConfirmationState(file, true);
          return;
        }

        mergeConflictsStore.setFileResolveMode(file, mode);
      },
      acceptDiscardConfirmation(file) {
        mergeConflictsStore.setPromptConfirmationState(file, false);
        mergeConflictsStore.setFileResolveMode(file, INTERACTIVE_RESOLVE_MODE);
      },
      cancelDiscardConfirmation(file) {
        mergeConflictsStore.setPromptConfirmationState(file, false);
      },
      commit() {
        mergeConflictsStore.setSubmitState(true);

        mergeConflictsService
          .submitResolveConflicts(mergeConflictsStore.getCommitData())
          .then(({ data }) => {
            window.location.href = data.redirect_to;
          })
          .catch(() => {
            mergeConflictsStore.setSubmitState(false);
            createFlash(__('Failed to save merge conflicts resolutions. Please try again!'));
          });
      },
    },
    render(createElement) {
      return createElement(MergeConflictsResolverApp);
    },
  });
}

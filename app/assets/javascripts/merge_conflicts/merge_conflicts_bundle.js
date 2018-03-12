/* eslint-disable new-cap, comma-dangle, no-new */

import $ from 'jquery';
import Vue from 'vue';
import Flash from '../flash';
import initIssuableSidebar from '../init_issuable_sidebar';
import './merge_conflict_store';
import './merge_conflict_service';
import './mixins/line_conflict_utils';
import './mixins/line_conflict_actions';
import './components/diff_file_editor';
import './components/inline_conflict_lines';
import './components/parallel_conflict_lines';
import syntaxHighlight from '../syntax_highlight';

export default function initMergeConflicts() {
  const INTERACTIVE_RESOLVE_MODE = 'interactive';
  const conflictsEl = document.querySelector('#conflicts');
  const mergeConflictsStore = gl.mergeConflicts.mergeConflictsStore;
  const mergeConflictsService = new gl.mergeConflicts.mergeConflictsService({
    conflictsPath: conflictsEl.dataset.conflictsPath,
    resolveConflictsPath: conflictsEl.dataset.resolveConflictsPath
  });

  initIssuableSidebar();

  gl.MergeConflictsResolverApp = new Vue({
    el: '#conflicts',
    components: {
      'diff-file-editor': gl.mergeConflicts.diffFileEditor,
      'inline-conflict-lines': gl.mergeConflicts.inlineConflictLines,
      'parallel-conflict-lines': gl.mergeConflicts.parallelConflictLines
    },
    data: mergeConflictsStore.state,
    computed: {
      conflictsCountText() { return mergeConflictsStore.getConflictsCountText(); },
      readyToCommit() { return mergeConflictsStore.isReadyToCommit(); },
      commitButtonText() { return mergeConflictsStore.getCommitButtonText(); },
      showDiffViewTypeSwitcher() { return mergeConflictsStore.fileTextTypePresent(); }
    },
    created() {
      mergeConflictsService.fetchConflictsData()
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
            new Flash('Failed to save merge conflicts resolutions. Please try again!');
          });
      }
    }
  });
}

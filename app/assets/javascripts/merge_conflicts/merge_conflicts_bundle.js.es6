//= require vue
//= require ./merge_conflict_store
//= require ./merge_conflict_service
//= require ./mixins/line_conflict_utils
//= require ./mixins/line_conflict_actions
//= require ./components/diff_file_editor
//= require ./components/inline_conflict_lines
//= require ./components/parallel_conflict_line
//= require ./components/parallel_conflict_lines

$(() => {
  const INTERACTIVE_RESOLVE_MODE = 'interactive';
  const $conflicts = $(document.getElementById('conflicts'));
  const mergeConflictsStore = gl.mergeConflicts.mergeConflictsStore;
  const mergeConflictsService = new gl.mergeConflicts.mergeConflictsService({
    conflictsPath: $conflicts.data('conflictsPath'),
    resolveConflictsPath: $conflicts.data('resolveConflictsPath')
  });

  gl.MergeConflictsResolverApp   = new Vue({
    el: '#conflicts',
    data: mergeConflictsStore.state,
    components: {
      'diff-file-editor': gl.mergeConflicts.diffFileEditor,
      'inline-conflict-lines': gl.mergeConflicts.inlineConflictLines,
      'parallel-conflict-lines': gl.mergeConflicts.parallelConflictLines
    },
    computed: {
      conflictsCountText() { return mergeConflictsStore.getConflictsCountText() },
      readyToCommit() { return mergeConflictsStore.isReadyToCommit() },
      commitButtonText() { return mergeConflictsStore.getCommitButtonText() },
      showDiffViewTypeSwitcher() { return mergeConflictsStore.fileTextTypePresent() }
    },
    created() {
      mergeConflictsService
        .fetchConflictsData()
        .done((data) => {
          if (data.type === 'error') {
            mergeConflictsStore.setFailedRequest(data.message);
          } else {
            mergeConflictsStore.setConflictsData(data);
          }
        })
        .error(() => {
          mergeConflictsStore.setFailedRequest();
        })
        .always(() => {
          mergeConflictsStore.setLoadingState(false);

          this.$nextTick(() => {
            $conflicts.find('.js-syntax-highlight').syntaxHighlight();
          });
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
          .done((data) => {
            window.location.href = data.redirect_to;
          })
          .error(() => {
            mergeConflictsStore.setSubmitState(false);
            new Flash('Failed to save merge conflicts resolutions. Please try again!');
          });
      }
    }
  })
});

//= require vue
//= require ./merge_conflict_store
//= require ./merge_conflict_service
//= require ./components/diff_file_editor

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
      'diff-file-editor': gl.mergeConflicts.diffFileEditor
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
      handleSelected(file, sectionId, selection) {
        mergeConflictsStore.handleSelected(file, sectionId, selection);
      },
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

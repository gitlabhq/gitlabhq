//= require vue
//= require ./merge_conflicts/components/diff_file_editor

const INTERACTIVE_RESOLVE_MODE = 'interactive';
const EDIT_RESOLVE_MODE = 'edit';

class MergeConflictResolver {

  constructor() {
    this.dataProvider = new MergeConflictDataProvider();
    this.initVue();
  }

  initVue() {
    const that = this;
    this.vue   = new Vue({
      el       : '#conflicts',
      name     : 'MergeConflictResolver',
      data     : this.dataProvider.getInitialData(),
      created  : this.fetchData(),
      computed : this.setComputedProperties(),
      methods  : {
        handleSelected(file, sectionId, selection) {
          that.dataProvider.handleSelected(file, sectionId, selection);
        },
        handleViewTypeChange(newType) {
          that.dataProvider.updateViewType(newType);
        },
        commit() {
          that.commit();
        },
        onClickResolveModeButton(file, mode) {
          that.toggleResolveMode(file, mode);
        },
        acceptDiscardConfirmation(file) {
          that.dataProvider.setPromptConfirmationState(file, false);
          that.dataProvider.setFileResolveMode(file, INTERACTIVE_RESOLVE_MODE);
        },
        cancelDiscardConfirmation(file) {
          that.dataProvider.setPromptConfirmationState(file, false);
        },
      },
      components: {
        'diff-file-editor': window.gl.diffFileEditor
      }
    })
  }


  setComputedProperties() {
    const dp = this.dataProvider;

    return {
      conflictsCount() { return dp.getConflictsCount() },
      readyToCommit() { return dp.isReadyToCommit() },
      commitButtonText() { return dp.getCommitButtonText() }
    }
  }


  fetchData() {
    const dp = this.dataProvider;

    $.get($('#conflicts').data('conflictsPath'))
      .done((data) => {
        dp.decorateData(this.vue, data);
      })
      .error((data) => {
        dp.handleFailedRequest(this.vue, data);
      })
      .always(() => {
        this.vue.isLoading = false;

        this.vue.$nextTick(() => {
          $('#conflicts .js-syntax-highlight').syntaxHighlight();
        });

        $('.content-wrapper .container-fluid')
          .toggleClass('container-limited', !this.vue.isParallel && this.vue.fixedLayout);
      })
  }


  commit() {
    this.vue.isSubmitting = true;

    $.ajax({
      url: $('#conflicts').data('resolveConflictsPath'),
      data: JSON.stringify(this.dataProvider.getCommitData()),
      contentType: "application/json",
      dataType: 'json',
      method: 'POST'
    })
    .done((data) => {
      window.location.href = data.redirect_to;
    })
    .error(() => {
      this.vue.isSubmitting = false;
      new Flash('Something went wrong!');
    });
  }


  toggleResolveMode(file, mode) {
    if (mode === INTERACTIVE_RESOLVE_MODE && file.resolveEditChanged) {
      this.dataProvider.setPromptConfirmationState(file, true);
      return;
    }

    this.dataProvider.setFileResolveMode(file, mode);
  }
}

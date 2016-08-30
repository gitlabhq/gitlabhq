//= require vue

class MergeConflictResolver {

  constructor() {
    this.dataProvider = new MergeConflictDataProvider()
    this.initVue()
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
        handleSelected(sectionId, selection) {
          that.dataProvider.handleSelected(sectionId, selection);
        },
        handleViewTypeChange(newType) {
          that.dataProvider.updateViewType(newType);
        },
        commit() {
          that.commit();
        }
      }
    })
  }


  setComputedProperties() {
    const dp = this.dataProvider;

    return {
      conflictsCount() { return dp.getConflictsCount() },
      resolvedCount() { return dp.getResolvedCount() },
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

        if (this.vue.diffViewType === 'parallel') {
          $('.content-wrapper .container-fluid').removeClass('container-limited');
        }
      })
  }


  commit() {
    this.vue.isSubmitting = true;

    $.post($('#conflicts').data('resolveConflictsPath'), this.dataProvider.getCommitData())
      .done((data) => {
        window.location.href = data.redirect_to;
      })
      .error(() => {
        this.vue.isSubmitting = false;
        new Flash('Something went wrong!');
      });
  }

}

//= require lib/vue

window.MergeConflictResolver = class MergeConflictResolver {

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
        }
      }
    })
  }


  fetchData() {
    $.get('./conflicts.json').done( (data) => {
      this.dataProvider.decorateData(this.vue, data);
      this.vue.isLoading = false;
    })
  }


  setComputedProperties() {
    const dp = this.dataProvider;

    return {
      conflictsCount() { return dp.getConflictsCount() },
      resolvedCount()  { return dp.getResolvedCount() },
      allResolved()    { return dp.isAllResolved() }
    }
  }

}

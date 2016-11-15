((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.CycleAnalyticsStore = {
    state: {
      summary: '',
      stats: '',
      analytics: '',
      items: [],
      stages:[
        {
          name:'Issue',
          active: false,
          component: 'stage-issue-component',
          legendTitle: 'Related Issues',
          shortDescription: 'Time before an issue get scheduled',
        },
        {
          name:'Plan',
          active: false,
          component: 'stage-plan-component',
          legendTitle: 'Related Commits',
          shortDescription: 'Time before an issue starts implementation',
        },
        {
          name:'Code',
          active: false,
          component: 'stage-code-component',
          legendTitle: 'Related Merge Requests',
          shortDescription: 'Time spent coding',
        },
        {
          name:'Test',
          active: false,
          component: 'stage-test-component',
          legendTitle: 'Relative Builds Trigger by Commits',
          shortDescription: 'The time taken to build and test the application',
        },
        {
          name:'Review',
          active: false,
          component: 'stage-review-component',
          legendTitle: 'Relative Merged Requests',
          shortDescription: 'The time taken to review the code',
        },
        {
          name:'Staging',
          active: false,
          component: 'stage-staging-component',
          legendTitle: 'Relative Deployed Builds',
          shortDescription: 'The time taken in staging',
        },
        {
          name:'Production',
          active: false,
          component: 'stage-production-component',
          legendTitle: 'Related Issues',
          shortDescription: 'The total time taken from idea to production',
        }
      ],
    },
    setCycleAnalyticsData(data) {
      this.state = Object.assign(this.state, this.decorateData(data));
    },
    decorateData(data) {
      let newData = {};

      newData.stats = data.stats || [];
      newData.summary = data.summary || [];

      newData.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      newData.stats.forEach((item) => {
        item.value = item.value || '- - -';
      });

      newData.analytics = data;      

      return newData;
    },
    setLoadingState(state) {
      this.state.isLoading = state;
    },
    setErrorState(state) {
      this.state.hasError = state;
    },
    deactivateAllStages() {
      this.state.stages.forEach(stage => {
        stage.active = false;
      });
    },
    setActiveStage(stage) {
      this.deactivateAllStages();
      stage.active = true;
    },
    setStageItems(items) {
      this.state.items = items;
    },
    currentActiveStage() {
      return this.state.stages.find(stage => stage.active);
    },
  };

})(window.gl || (window.gl = {}));

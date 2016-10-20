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
        },
        {
          name:'Plan',
          active: false,
          component: 'stage-plan-component',
          legendTitle: 'Related Commits',
        },
        {
          name:'Code',
          active: false,
          component: 'stage-code-component',
          legendTitle: 'Related Merge Requests',
        },
        {
          name:'Test',
          active: false,
          component: 'stage-test-component',
          legendTitle: 'Relative Builds Trigger by Commits',
        },
        {
          name:'Review',
          active: false,
          component: 'stage-review-component',
          legendTitle: 'Relative Merged Requests',
        },
        {
          name:'Staging',
          active: false,
          component: 'stage-staging-component',
          legendTitle: 'Relative Deployed Builds',
        },
        {
          name:'Production',
          active: false,
          component: 'stage-production-component',
          legendTitle: 'Related Issues',
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

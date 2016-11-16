((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.CycleAnalyticsStore = {
    state: {
      summary: '',
      stats: '',
      analytics: '',
      items: [],
      stages:[],
    },
    setCycleAnalyticsData(data) {
      this.state = Object.assign(this.state, this.decorateData(data));
    },
    decorateData(data) {
      let newData = {};

      newData.stages = data.stats || [];
      newData.summary = data.summary || [];

      newData.summary.forEach((item) => {
        item.value = item.value || '-';
      });

      newData.stages.forEach((item) => {
        item.value = item.value || '- - -';
        item.active = false;
        item.component = `stage-${item.title.toLowerCase()}-component`;
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

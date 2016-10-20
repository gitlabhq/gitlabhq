((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.CycleAnalyticsStore = {
    state: {
      isLoading: true,
      hasError: false,
      summary: '',
      stats: '',
      analytics: ''
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
    }
  };

})(window.gl || (window.gl = {}));

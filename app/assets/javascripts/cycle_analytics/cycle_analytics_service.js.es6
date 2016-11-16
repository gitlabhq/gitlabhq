((global) => {
  global.cycleAnalytics = global.cycleAnalytics || {};

  class CycleAnalyticsService {
    constructor(options) {
      this.requestPath = options.requestPath;
    }

    fetchCycleAnalyticsData(options) {
      options = options || { startDate: 30 };

      return $.ajax({
        url: this.requestPath,
        method: 'GET',
        dataType: 'json',
        contentType: 'application/json',
        data: {
          cycle_analytics: {
            start_date: options.startDate
          }
        }
      });
    }

    fetchStageData(options) {
      let {
        stage,
        startDate,
      } = options;

      return $.get(`http://localhost:8000/${stage.title.toLowerCase()}.json`, {
        cycle_analytics: {
          start_date: options.startDate
        }
      });
    }
  };

  global.cycleAnalytics.CycleAnalyticsService = CycleAnalyticsService;

})(window.gl || (window.gl = {}));

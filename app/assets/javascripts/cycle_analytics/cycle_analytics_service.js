/* eslint-disable no-param-reassign */

const global = window.gl || (window.gl = {});
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
      data() {
        return {
          cycle_analytics: {
            start_date: options.startDate,
          },
        };
      },
    });
  }

  fetchStageData(options) {
    const {
      stage,
      startDate,
    } = options;

    return $.get(`${this.requestPath}/events/${stage.name}.json`, {
      cycle_analytics: {
        start_date: startDate,
      },
    });
  }
}

global.cycleAnalytics.CycleAnalyticsService = CycleAnalyticsService;

import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class CycleAnalyticsService {
  constructor(options) {
    this.requestPath = options.requestPath;
    this.cycleAnalytics = Vue.resource(this.requestPath);
  }

  fetchCycleAnalyticsData(options = { startDate: 30 }) {
    return this.cycleAnalytics.get({ cycle_analytics: { start_date: options.startDate } });
  }

  fetchStageData(options) {
    const {
      stage,
      startDate,
    } = options;

    return Vue.http.get(`${this.requestPath}/events/${stage.name}.json`, {
      params: {
        cycle_analytics: {
          start_date: startDate,
        },
      },
    });
  }
}

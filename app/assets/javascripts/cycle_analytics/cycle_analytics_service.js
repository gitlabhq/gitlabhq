import axios from '~/lib/utils/axios_utils';

export default class CycleAnalyticsService {
  constructor(options) {
    this.axios = axios.create({
      baseURL: options.requestPath,
    });
  }

  fetchCycleAnalyticsData(options = { startDate: 30 }) {
    return this.axios
      .get('', {
        params: {
          'cycle_analytics[start_date]': options.startDate,
        },
      })
      .then(x => x.data);
  }

  fetchStageData(options) {
    const {
      stage,
      startDate,
    } = options;

    return this.axios
      .get(`events/${stage.name}.json`, {
        params: {
          'cycle_analytics[start_date]': startDate,
        },
      })
      .then(x => x.data);
  }
}

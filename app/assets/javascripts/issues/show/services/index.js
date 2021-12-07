import axios from '~/lib/utils/axios_utils';

export default class Service {
  constructor(endpoint) {
    this.endpoint = `${endpoint}.json`;
    this.realtimeEndpoint = `${endpoint}/realtime_changes`;
  }

  getData() {
    return axios.get(this.realtimeEndpoint);
  }

  deleteIssuable(payload) {
    return axios.delete(this.endpoint, { params: payload });
  }

  updateIssuable(data) {
    return axios.put(this.endpoint, data);
  }

  // eslint-disable-next-line class-methods-use-this
  loadTemplates(templateNamesEndpoint) {
    if (!templateNamesEndpoint) {
      return Promise.resolve([]);
    }

    return axios.get(templateNamesEndpoint);
  }
}

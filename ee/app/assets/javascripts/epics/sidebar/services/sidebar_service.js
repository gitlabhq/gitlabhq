import axios from '~/lib/utils/axios_utils';

export default class SidebarService {
  constructor(endpoint, subscriptionEndpoint) {
    this.endpoint = endpoint;
    this.subscriptionEndpoint = subscriptionEndpoint;
  }

  updateStartDate(startDate) {
    return axios.put(this.endpoint, { start_date: startDate });
  }

  updateEndDate(endDate) {
    return axios.put(this.endpoint, { end_date: endDate });
  }

  toggleSubscribed() {
    return axios.post(this.subscriptionEndpoint);
  }
}

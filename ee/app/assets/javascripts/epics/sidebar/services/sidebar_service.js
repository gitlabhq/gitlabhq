import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class SidebarService {
  constructor(endpoint) {
    this.endpoint = endpoint;
    this.resource = Vue.resource(`${this.endpoint}.json`, {});
  }

  updateStartDate(startDate) {
    return this.resource.update({
      start_date: startDate,
    });
  }

  updateEndDate(endDate) {
    return this.resource.update({
      end_date: endDate,
    });
  }
}

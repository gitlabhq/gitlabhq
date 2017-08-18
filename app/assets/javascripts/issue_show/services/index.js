import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class Service {
  constructor(endpoint) {
    this.endpoint = endpoint;

    this.resource = Vue.resource(`${this.endpoint}.json`, {}, {
      realtimeChanges: {
        method: 'GET',
        url: `${this.endpoint}/realtime_changes`,
      },
    });
  }

  getData() {
    return this.resource.realtimeChanges();
  }

  deleteIssuable() {
    return this.resource.delete();
  }

  updateIssuable(data) {
    return this.resource.update(data);
  }
}

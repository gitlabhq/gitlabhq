import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class Service {
  constructor(endpoint) {
    this.endpoint = endpoint;

    this.resource = Vue.resource(this.endpoint, {}, {
      rendered_title: {
        method: 'GET',
        url: `${this.endpoint}/rendered_title`,
      },
    });
  }

  getData() {
    return this.resource.rendered_title();
  }

  deleteIssuable() {
    return this.resource.delete()
      .then(res => res.json());
  }

  updateIssuable(data) {
    return this.resource.update(data)
      .then(res => res.json());
  }
}

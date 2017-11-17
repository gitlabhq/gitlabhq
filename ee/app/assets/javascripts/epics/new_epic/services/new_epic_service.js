import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class NewEpicService {
  constructor(endpoint) {
    this.endpoint = endpoint;
    this.resource = Vue.resource(this.endpoint, {});
  }

  createEpic(title) {
    return this.resource.save({
      title,
    });
  }
}

/* eslint-disable class-methods-use-this */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
  }

  get(scope, page) {
    return this.environments.get({ scope, page });
  }

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }

  getFolderContent(folderUrl) {
    const results = 3;
    return Vue.http.get(`${folderUrl}.json?per_page=${results}`);
  }
}

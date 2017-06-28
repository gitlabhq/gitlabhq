/* eslint-disable class-methods-use-this */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environments = Vue.resource(endpoint);
    this.folderResults = 3;
  }

  get(options = {}) {
    const { scope, page } = options;
    return this.environments.get({ scope, page });
  }

  postAction(endpoint) {
    return Vue.http.post(endpoint, {}, { emulateJSON: true });
  }

  getFolderContent(folderUrl) {
    return Vue.http.get(`${folderUrl}.json?per_page=${this.folderResults}`);
  }
}

/* eslint-disable class-methods-use-this */
import Vue from 'vue';
import VueResource from 'vue-resource';
import '../../vue_shared/vue_resource_interceptor';

Vue.use(VueResource);

export default class PipelinesService {

  /**
  * Commits and merge request endpoints need to be requested with `.json`.
  *
  * The url provided to request the pipelines in the new merge request
  * page already has `.json`.
  *
  * @param  {String} root
  */
  constructor(root) {
    let endpoint;

    if (root.indexOf('.json') === -1) {
      endpoint = `${root}.json`;
    } else {
      endpoint = root;
    }

    this.pipelines = Vue.resource(endpoint);
  }

  getPipelines(data = {}) {
    const { scope, page } = data;
    return this.pipelines.get({ scope, page });
  }

  /**
   * Post request for all pipelines actions.
   *
   * @param  {String} endpoint
   * @return {Promise}
   */
  postAction(endpoint) {
    return Vue.http.post(`${endpoint}.json`);
  }
}

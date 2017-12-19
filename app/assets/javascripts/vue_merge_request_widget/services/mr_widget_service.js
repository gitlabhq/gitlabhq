import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MRWidgetService {
  constructor(endpoints) {
    this.mergeResource = Vue.resource(endpoints.mergePath);
    this.mergeCheckResource = Vue.resource(endpoints.statusPath);
    this.cancelAutoMergeResource = Vue.resource(endpoints.cancelAutoMergePath);
    this.removeWIPResource = Vue.resource(endpoints.removeWIPPath);
    this.removeSourceBranchResource = Vue.resource(endpoints.sourceBranchPath);
    this.deploymentsResource = Vue.resource(endpoints.ciEnvironmentsStatusPath);
    this.pollResource = Vue.resource(`${endpoints.statusPath}?serializer=basic`);
    this.mergeActionsContentResource = Vue.resource(endpoints.mergeActionsContentPath);
  }

  merge(data) {
    return this.mergeResource.save(data);
  }

  cancelAutomaticMerge() {
    return this.cancelAutoMergeResource.save();
  }

  removeWIP() {
    return this.removeWIPResource.save();
  }

  removeSourceBranch() {
    return this.removeSourceBranchResource.delete();
  }

  fetchDeployments() {
    return this.deploymentsResource.get();
  }

  poll() {
    return this.pollResource.get();
  }

  checkStatus() {
    return this.mergeCheckResource.get();
  }

  fetchMergeActionsContent() {
    return this.mergeActionsContentResource.get();
  }

  static stopEnvironment(url) {
    return Vue.http.post(url);
  }

  static fetchMetrics(metricsUrl) {
    return Vue.http.get(`${metricsUrl}.json`);
  }
}

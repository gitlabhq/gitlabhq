import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MRWidgetService {
  constructor(mr) {
    this.store = mr;

    this.mergeResource = Vue.resource(mr.mergePath);
    this.mergeCheckResource = Vue.resource(mr.mergeCheckPath);
    this.cancelAutoMergeResource = Vue.resource(mr.cancelAutoMergePath);
    this.removeWIPResource = Vue.resource(mr.removeWIPPath);
    this.removeSourceBranchResource = Vue.resource(mr.sourceBranchPath);
    this.deploymentsResource = Vue.resource(mr.ciEnvironmentsStatusPath);
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
    this.deploymentsResource.get()
      .then(res => res.json())
      .then((res) => {
        if (res.length) {
          this.store.deployments = res;
        }
      });
  }

  checkStatus() {
    return this.mergeCheckResource.get();
  }
}

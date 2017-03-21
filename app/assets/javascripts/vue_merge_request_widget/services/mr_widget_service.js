import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MRWidgetService {
  constructor(mr) {
    this.mergeResource = Vue.resource(mr.mergePath);
    this.cancelAutoMergeResource = Vue.resource(mr.cancelAutoMergePath);
    this.removeWIPResource = Vue.resource(mr.removeWIPPath);
    this.removeSourceBranchResource = Vue.resource(mr.sourceBranchPath);
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

}

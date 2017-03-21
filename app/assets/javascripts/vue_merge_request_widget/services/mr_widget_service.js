import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MRWidgetService {
  constructor(mr) {
    this.mergeResource = Vue.resource(mr.mergePath);
    this.cancelAutoMergeResource = Vue.resource(mr.cancelAutoMergePath);
  }

  merge(data) {
    return this.mergeResource.save(data);
  }

  cancelAutomaticMerge() {
    return this.cancelAutoMergeResource.save();
  }

}

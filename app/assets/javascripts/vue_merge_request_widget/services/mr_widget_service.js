import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

export default class MRWidgetService {
  constructor(mr) {
    this.mergeResource = Vue.resource(mr.mergePath);
    // TODO: @fatihacet - Implement this.
    this.setMergeWhenBuildSucceedsResource = Vue.resource(mr.setMergeWhenBuildSucceedsPath);
  }

  merge(options) {
    return this.mergeResource.save(options);
  }

  setToMergeWhenBuildSucceeds() {
    // TODO: @fatihacet - Implement this.
    return this.setMergeWhenBuildSucceedsResource.save();
  }
}

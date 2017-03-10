import Vue from 'vue';
import VueResource from 'vue-resource';
Vue.use(VueResource);

export default class MRWidgetService {
  constructor(mr) {
    this.mergeService = Vue.resource(mr.mergePath);
  }

  merge(options) {
    return this.mergeService.save(options);
  }
}

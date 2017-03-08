import Vue from 'vue';

export default class MRWidgetService {
  constructor(mr) {
    this.mergeService = Vue.resource(mr.mergePath);
  }

  merge(options) {
    return this.mergeService.save(options);
  }
}

import Vue from 'vue';
import Store from './repo_store';

export default class RepoViewToggler {
  constructor() {
    this.initVue();
  }

  initVue() {
    this.vue = new Vue({
      el: '#view-toggler',

      data: () => Store,
    });
  }
}

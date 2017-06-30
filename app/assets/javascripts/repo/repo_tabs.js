import Vue from 'vue';
import Store from './repo_store'
import RepoTab from './repo_tab'
import RepoMiniMixin from './repo_mini_mixin'

export default class RepoTabs {
  constructor() {
    this.initVue();
  }

  initVue() {
    this.vue = new Vue({
      el: '#tabs',
      mixins: [RepoMiniMixin],
      components: {
        'repo-tab': RepoTab,
      },
      data: () => Store,
    });
  }
}
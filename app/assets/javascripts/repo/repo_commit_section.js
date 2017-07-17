import Vue from 'vue';
import Store from './repo_store';

export default class RepoCommitSection {
  constructor() {
    this.initVue();
    this.el = document.getElementById('commit-area');
  }

  initVue() {
    this.vue = new Vue({
      el: '#commit-area',
      data: () => Store,

      computed: {
        changedFiles() {
          const changedFileList = this.openedFiles
          .filter(file => file.changed);
          return changedFileList;
        },
      },
    });
  }
}

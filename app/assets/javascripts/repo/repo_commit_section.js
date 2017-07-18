import Vue from 'vue';
import Store from './repo_store';

export default class RepoCommitSection {
  constructor(el) {
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
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

import Service from './repo_service'
import Vue from 'vue';

export default class RepoSidebar {
  constructor(url) {
    this.url = url;
    this.getTree();
    this.initVue();
  }

  getTree() {
    Service.getTree()
    .then((response)=> {
      console.log('response', response.data);
    })
    .catch((response)=> {
      console.log('error response', response);
    });
  }

  initVue() {
    this.vue = new Vue({

    });
  }
}
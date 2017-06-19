import Service from './repo_service'
import Helper from './repo_helper'
import Vue from 'vue';
import Store from './repo_store'

export default class RepoSidebar {
  constructor(url) {
    this.url = url;
    this.initVue();
  }

  // may be tree or file.
  getContent() {
    Service.getContent()
    .then((response)=> {
      let data = response.data;
      Store.isTree = Helper.isTree(data);
      if(!Store.isTree) {
        Store.blobRaw = data.plain;
      }
    })
    .catch((response)=> {
      console.log('error response', response);
    });
  }

  initVue() {}
}
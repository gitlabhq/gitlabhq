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
        // it's a blob
        const parentURL = Helper.blobURLtoParent(Service.url);
        Store.blobRaw = data.plain;
        Service.getContent(parentURL + '/?format=json')
        .then((response)=> {
          console.log(response.data)
        })
        .catch((response)=> {

        });
      } else {
      }
    })
    .catch((response)=> {
      console.log('error response', response);
    });
  }

  initVue() {}
}
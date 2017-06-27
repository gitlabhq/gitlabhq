import Service from './repo_service'
import Helper from './repo_helper'
import Vue from 'vue'
import Store from './repo_store'
import RepoFile from './repo_file'

export default class RepoSidebar {
  constructor(url) {
    this.url = url;
    this.initVue();
    this.el = document.getElementById('ide');
  }

  initVue() {
    this.vue = new Vue({
      el: '#sidebar',
      components: {
        'repo-file':RepoFile,
      },

      created() {
        this.addPopEventListener();
      },

      data: () => Store,

      methods: {
        addPopEventListener() {
          window.addEventListener('popstate', () => {
            this.linkClicked({
              url: location.href
            });
          });
        },

        linkClicked(file) {
          Service.url = file.url;
          Helper.getContent();
          Helper.toURL(file.url);
        }
      }
    });
  }
}
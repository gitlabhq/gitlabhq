import Service from './repo_service'
import Helper from './repo_helper'
import Vue from 'vue'
import Store from './repo_store'
import RepoPreviousDirectory from './repo_prev_directory'
import RepoFileOptions from './repo_file_options'
import RepoFile from './repo_file'
import RepoLoadingFile from './repo_loading_file'
import RepoMiniMixin from './repo_mini_mixin'

export default class RepoSidebar {
  constructor(url) {
    this.url = url;
    this.initVue();
    this.el = document.getElementById('ide');
  }

  initVue() {
    this.vue = new Vue({
      el: '#sidebar',
      mixins: [RepoMiniMixin],
      components: {
        'repo-file-options': RepoFileOptions,
        'repo-previous-directory': RepoPreviousDirectory,
        'repo-file': RepoFile,
        'repo-loading-file': RepoLoadingFile,
      },

      created() {
        this.addPopEventListener();
      },

      data: () => Store,

      methods: {
        addPopEventListener() {
          window.addEventListener('popstate', () => {
            if(location.href.indexOf('#') > -1) return;
            this.linkClicked({
              url: location.href
            });
          });
        },

        linkClicked(file) {
          console.log('link clicked')
          let url = '';
          if(typeof file === 'object') {
            if(file.type === 'tree' && file.opened) {
              Helper.removeChildFilesOfTree(file);
              return;
            } else {
              url = file.url;
              Service.url = url;
              Helper.getContent(file);
            }
          } else if(typeof file === 'string') {
            // go back
            url = file;
            Service.url = url;
            Helper.getContent();
          }
        }
      },
    });
  }
}
import Vue from 'vue';
import Service from './repo_service';
import Helper from './repo_helper';
import Store from './repo_store';
import RepoPreviousDirectory from './repo_prev_directory.vue';
import RepoFileOptions from './repo_file_options.vue';
import RepoFile from './repo_file.vue';
import RepoLoadingFile from './repo_loading_file.vue';
import RepoMiniMixin from './repo_mini_mixin';

export default class RepoSidebar {
  constructor(el) {
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
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
            if (location.href.indexOf('#') > -1) return;
            this.linkClicked({
              url: location.href,
            });
          });
        },

        linkClicked(clickedFile) {
          let url = '';
          let file = clickedFile;
          file.loading = true;
          if (typeof file === 'object') {
            if (file.type === 'tree' && file.opened) {
              file = Store.removeChildFilesOfTree(file);
            } else {
              url = file.url;
              Service.url = url;
              // I need to refactor this to do the `then` here.
              // Not a callback. For now this is good enough.
              // it works.
              Helper.getContent(file, () => {
                file.loading = false;
              });
            }
          } else if (typeof file === 'string') {
            // go back
            url = file;
            Service.url = url;
            Helper.getContent(null, () => {
              file.loading = false;
            });
          }
        },
      },
    });
  }
}

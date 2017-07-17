<<<<<<< HEAD
import Vue from 'vue'
import Store from './repo_store'
import Helper from './repo_helper'
import RepoMiniMixin from './repo_mini_mixin'
=======
import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d

export default class RepoSidebar {
  constructor(url) {
    this.url = url;
    this.initVue();
    this.el = document.getElementById('repo-file-buttons');
  }

  initVue() {
    this.vue = new Vue({
      el: '#repo-file-buttons',
      data: () => Store,
      mixins: [RepoMiniMixin],
      template: `
      <div id='repo-file-buttons' v-if='isMini' :style='{"border-bottom": editableBorder}'>
        <a :href='rawFileURL' target='_blank' class='btn btn-default'>Download file</a>
        <div class="btn-group" role="group" aria-label="File actions">
          <a :href='blameFileUrl' class='btn btn-default'>Blame</a>
          <a :href='historyFileUrl' class='btn btn-default'>History</a>
          <a href='#' class='btn btn-default'>Permalink</a>
          <a href='#' class='btn btn-default'>Lock</a>
        </div>
        <a href='#' v-if='canPreview' @click.prevent='rawPreviewToggle' class='btn btn-default'>
          {{activeFileLabel}}
        </a>
        <a href='#' class='btn btn-danger'>Delete</a>
      </div>
      `,
      computed: {
<<<<<<< HEAD

        editableBorder() {
          return this.editMode ? '1px solid #1F78D1' :'1px solid #f0f0f0';
=======
        previewLabel() {
          return this.activeFile.raw ? 'Preview' : 'Raw';
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
        },

        canPreview() {
          return this.activeFile.extension === 'md';
        },

        rawFileURL() {
          return Helper.getRawURLFromBlobURL(this.activeFile.url);
        },

        blameFileUrl() {
          return Helper.getBlameURLFromBlobURL(this.activeFile.url);
        },

        historyFileUrl() {
          return Helper.getHistoryURLFromBlobURL(this.activeFile.url);
        },
      },

      methods: {
<<<<<<< HEAD
        rawPreviewToggle() {
          Helper.setCurrentFileRawOrPreview();
        }
=======
        setRawPreviewMode() {

        },
>>>>>>> 51a936fb3d2cdbd133a3b0eed463b47c1c92fe7d
      },
    });
  }
}

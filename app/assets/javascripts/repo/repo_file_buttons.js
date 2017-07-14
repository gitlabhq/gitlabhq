import Vue from 'vue'
import Store from './repo_store'
import Helper from './repo_helper'

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
      template: `
      <div id='repo-file-buttons' v-if='!isTree'>
        <a :href='rawFileURL' target='_blank' class='btn btn-default'>Download file</a>
        <div class="btn-group" role="group" aria-label="File actions">
          <a :href='blameFileUrl' class='btn btn-default'>Blame</a>
          <a :href='historyFileUrl' class='btn btn-default'>History</a>
          <a href='#' class='btn btn-default'>Permalink</a>
          <a href='#' class='btn btn-default'>Lock</a>
        </div>
        <a href='#' v-if='canPreview' class='btn btn-default'>{{previewLabel}}</a>
        <a href='#' class='btn btn-danger'>Delete</a>
      </div>
      `,
      computed: {
        previewLabel() {
          return this.activeFile.raw ? 'Preview' : 'Raw'
        },

        canPreview() {
          return this.activeFile.extension === 'md';
        },

        rawFileURL() {
          console.log(this.activeFile)
          return Helper.getRawURLFromBlobURL(this.activeFile.url);
        },

        blameFileUrl() {
          return Helper.getBlameURLFromBlobURL(this.activeFile.url);
        },

        historyFileUrl() {
          return Helper.getHistoryURLFromBlobURL(this.activeFile.url);
        }
      },

      methods: {
        setRawPreviewMode() {

        }
      }
    });
  }
}
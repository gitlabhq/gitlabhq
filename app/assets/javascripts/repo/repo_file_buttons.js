import Vue from 'vue';
import Store from './repo_store';
import Helper from './repo_helper';
import RepoMiniMixin from './repo_mini_mixin';

export default class RepoFileButtons {
  constructor(el) {
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
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

        editableBorder() {
          return this.editMode ? '1px solid #1F78D1' : '1px solid #f0f0f0';
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
        rawPreviewToggle: Store.toggleRawPreview,
      },
    });
  }
}

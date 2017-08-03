<script>
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';
import RepoMixin from '../mixins/repo_mixin';

const RepoFileButtons = {
  data: () => Store,

  mixins: [RepoMixin],

  computed: {

    rawDownloadButtonLabel() {
      return this.binary ? 'Download' : 'Raw';
    },

    editableBorder() {
      return this.editMode ? '1px solid rgb(31, 120, 209)' : '1px solid rgb(240,240,240)';
    },

    canPreview() {
      return Helper.isKindaBinary();
    },

    rawFileURL() {
      return Helper.getRawURLFromBlobURL(this.activeFile.url);
    },

    blameFileURL() {
      return Helper.getBlameURLFromBlobURL(this.activeFile.url);
    },

    historyFileURL() {
      return Helper.getHistoryURLFromBlobURL(this.activeFile.url);
    },
  },

  methods: {
    rawPreviewToggle: Store.toggleRawPreview,
  },
};

export default RepoFileButtons;
</script>

<template>
<div id="repo-file-buttons" v-if="isMini" :style="{'border-bottom': editableBorder}">
  <a :href="activeFile.raw_path" target="_blank" class="btn btn-default raw">{{rawDownloadButtonLabel}}</a>

  <div class="btn-group" role="group" aria-label="File actions">
    <a :href="activeFile.blame_path" class="btn btn-default blame">Blame</a>
    <a :href="activeFile.commits_path" class="btn btn-default history">History</a>
    <a href="activeFile.permalink" class="btn btn-default permalink">Permalink</a>
  </div>

  <a href="#" v-if="canPreview" @click.prevent="rawPreviewToggle" class="btn btn-default preview">{{activeFileLabel}}</a>
</div>
</template>

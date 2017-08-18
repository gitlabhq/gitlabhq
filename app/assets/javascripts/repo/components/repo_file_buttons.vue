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

    canPreview() {
      return Helper.isRenderable();
    },
  },

  methods: {
    rawPreviewToggle: Store.toggleRawPreview,
  },
};

export default RepoFileButtons;
</script>

<template>
  <div id="repo-file-buttons">
    <a
      :href="activeFile.raw_path"
      target="_blank"
      class="btn btn-default raw"
      rel="noopener noreferrer">
      {{rawDownloadButtonLabel}}
    </a>

    <div
      class="btn-group"
      role="group"
      aria-label="File actions">
      <a
        :href="activeFile.blame_path"
        class="btn btn-default blame">
        Blame
      </a>
      <a
        :href="activeFile.commits_path"
        class="btn btn-default history">
        History
      </a>
      <a
        :href="activeFile.permalink"
        class="btn btn-default permalink">
        Permalink
      </a>
    </div>

    <a
      v-if="canPreview"
      href="#"
      @click.prevent="rawPreviewToggle"
      class="btn btn-default preview">
      {{activeFileLabel}}
    </a>
  </div>
</template>

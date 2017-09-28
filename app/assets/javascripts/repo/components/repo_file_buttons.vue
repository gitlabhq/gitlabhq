<script>
import Store from '../stores/repo_store';
import Service from '../services/repo_service';
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
    showSimpleViewer() {
      Service
        .getContent(Store.activeFile.simple_viewer.path)
        .then((res) => {
          Store.activeFile.html = res.data.html;
        });
    },
    showRichViewer() {
      Service
        .getContent(Store.activeFile.rich_viewer.path)
        .then((res) => {
          Store.activeFile.html = res.data.html;
        });
    },
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

    <a
      @click="showSimpleViewer"
      target="_blank"
      class="btn btn-default raw"
      rel="noopener noreferrer">
      Simple View
    </a>
    <a
      @click="showRichViewer"
      target="_blank"
      class="btn btn-default raw"
      rel="noopener noreferrer">
      Rich View
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

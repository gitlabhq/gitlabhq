<script>
// TODO: There is no file raw content for the copy source button.
// TODO: Ask @douwe to confirm v-if="!activeFile.binary" for the copy source button.
// TODO: Make sure that we implement all possible cases for the button types.
// FIXME: Preserve preview mode when editor tabs are changed.

import Store from '../stores/repo_store';
import Service from '../services/repo_service';
import Helper from '../helpers/repo_helper';
import RepoMixin from '../mixins/repo_mixin';
import tooltip from '../../vue_shared/directives/tooltip';

const RepoFileButtons = {
  data: () => Store,
  mixins: [RepoMixin],
  directives: {
    tooltip,
  },
  computed: {
    rawDownloadButtonLabel() {
      return this.binary ? 'Download' : 'Open raw';
    },
    rawIcon() {
      return this.binary ? 'fa-download' : 'fa-file-code-o';
    },
    canPreview() {
      return Helper.isRenderable();
    },
    simpleViewerIconClass() {
      return this.activeFile.simple_viewer ? `fa fa-${this.activeFile.simple_viewer.switcher_icon}` : '';
    },
    richViewerIconClass() {
      return this.activeFile.rich_viewer ? `fa fa-${this.activeFile.rich_viewer.switcher_icon}` : '';
    },
    simpleViewerTooltip() {
      return this.activeFile.simple_viewer ? `Display ${this.activeFile.simple_viewer.switcher_title}` : '';
    },
    richViewerTooltip() {
      return this.activeFile.rich_viewer ? `Display ${this.activeFile.rich_viewer.switcher_title}` : '';
    },
  },
  methods: {
    toggleViewer(type, requestPath) {
      const { activeFile } = Store;
      const html = activeFile.viewerHTML[type];

      if (html) {
        activeFile.html = html;
        activeFile.previewMode = type;
      } else {
        Service
          .getContent(requestPath)
          .then((res) => {
            activeFile.previewMode = type;
            activeFile.html = res.data.html;
            activeFile.viewerHTML[type] = res.data.html;
          })
          .catch(Helper.loadingError);
      }
    },
    showSimpleViewer() {
      this.toggleViewer('simple', Store.activeFile.simple_viewer.path);
    },
    showRichViewer() {
      this.toggleViewer('rich', Store.activeFile.rich_viewer.path);
    },
  },
};

export default RepoFileButtons;
</script>

<template>
  <div id="repo-file-buttons">
    <div
      v-if="activeFile.rich_viewer && !editMode"
      class="btn-group"
      role="group"
      aria-label="File viewer actions">
      <a
        @click="showSimpleViewer"
        :title="simpleViewerTooltip"
        :class="{ active: activeFile.previewMode === 'simple' }"
        v-tooltip
        data-container="body"
        target="_blank"
        class="btn btn-default"
        rel="noopener noreferrer">
        <i
          :class="simpleViewerIconClass"
          aria-hidden="true"></i>
      </a>
      <a
        @click="showRichViewer"
        :title="richViewerTooltip"
        :class="{ active: activeFile.previewMode === 'rich' }"
        v-tooltip
        data-container="body"
        target="_blank"
        class="btn btn-default"
        rel="noopener noreferrer">
        <i
          :class="richViewerIconClass"
          aria-hidden="true"></i>
      </a>
    </div>

    <div
      class="btn-group"
      role="group"
      aria-label="File raw actions">
      <a
        :href="activeFile.raw_path"
        :title="rawDownloadButtonLabel"
        v-tooltip
        target="_blank"
        class="btn btn-default raw"
        rel="noopener noreferrer">
        <i
          :class="rawIcon"
          class="fa"
          aria-hidden="true"></i>
      </a>
      <button
        v-if="!activeFile.binary"
        v-tooltip
        class="btn btn-default"
        data-container="body"
        data-title="Copy source to clipboard"
        :data-clipboard-text="activeFile.raw_path">
        <i
          class="fa fa-clipboard"
          aria-hidden="true"></i>
      </button>
    </div>

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
  </div>
</template>

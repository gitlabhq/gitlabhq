<script>
import { mapGetters } from 'vuex';
import tooltip from '../../vue_shared/directives/tooltip.js';
import viewerSwitch from './blob_viewer_switch.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    viewerSwitch,
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'canActiveFileSwitchViewer',
    ]),
    showButtons() {
      return this.activeFile.rawPath ||
        this.activeFile.blamePath ||
        this.activeFile.commitsPath ||
        this.activeFile.permalink;
    },
    rawDownloadButtonLabel() {
      return this.activeFile.binary ? 'Download' : 'Raw';
    },
    rawDownloadButtonIcon() {
      return this.activeFile.binary ? 'fa-download' : 'fa-file-code-o';
    },
    blobContentElementSelector() {
      return `.blob-content[data-blob-id='${this.activeFile.id}']`;
    },
    copySourceButtonDisabled() {
      return this.activeFile.currentViewer !== 'simple';
    },
    copySourceButtonTitle() {
      return this.activeFile.currentViewer !== 'simple' ? 'Switch to source to copy it to clipboard' : 'Copy source to clipboard';
    },
  },
};
</script>

<template>
  <div
    v-if="showButtons"
    class="repo-file-buttons"
  >
    <viewer-switch
      v-if="canActiveFileSwitchViewer"
    />
    <div
      class="btn-group"
      role="group"
    >
      <button
        v-tooltip
        v-if="canActiveFileSwitchViewer"
        type="button"
        class="btn btn-default btn-sm"
        :class="{
          disabled: copySourceButtonDisabled,
        }"
        :title="copySourceButtonTitle"
        :aria-label="copySourceButtonTitle"
        data-container="body"
       :data-clipboard-target="blobContentElementSelector"
      >
        <i
          aria-hidden="true"
          class="fa fa-clipboard"
        >
        </i>
      </button>
      <a
        :href="activeFile.rawPath"
        target="_blank"
        class="btn btn-default btn-sm raw"
        rel="noopener noreferrer"
        :aria-label="rawDownloadButtonLabel"
      >
        <i
          class="fa"
          :class="rawDownloadButtonIcon"
          aria-hidden="true"
        >
        </i>
      </a>
    </div>
    <div
      class="btn-group"
      role="group"
      aria-label="File actions">
      <a
        :href="activeFile.blamePath"
        class="btn btn-default btn-sm blame">
        Blame
      </a>
      <a
        :href="activeFile.commitsPath"
        class="btn btn-default btn-sm history">
        History
      </a>
      <a
        :href="activeFile.permalink"
        class="btn btn-default btn-sm permalink">
        Permalink
      </a>
    </div>
  </div>
</template>

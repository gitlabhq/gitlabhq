<script>
import { mapGetters } from 'vuex';
import tooltip from '../../vue_shared/directives/tooltip';
import viewerSwitch from './blob_viewer_switch.vue';
import sourceCopyButton from './source_copy_button.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    viewerSwitch,
    sourceCopyButton,
  },
  computed: {
    ...mapGetters([
      'activeFile',
      'canActiveFileSwitchViewer',
      'canCopySource',
    ]),
    showButtons() {
      return this.activeFile.rawPath ||
        this.activeFile.blamePath ||
        this.activeFile.commitsPath ||
        this.activeFile.permalink;
    },
    rawDownloadButtonLabel() {
      return this.activeFile.binary || this.activeFile.storedExternally ? 'Download' : 'Open raw';
    },
    rawDownloadButtonIcon() {
      return this.activeFile.binary || this.activeFile.storedExternally ? 'fa-download' : 'fa-file-code-o';
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
      <source-copy-button
        v-if="canCopySource"
      />
      <a
        v-tooltip
        :href="activeFile.rawPath"
        target="_blank"
        class="btn btn-default btn-sm raw"
        rel="noopener noreferrer"
        :aria-label="rawDownloadButtonLabel"
        :title="rawDownloadButtonLabel"
        data-container="body"
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

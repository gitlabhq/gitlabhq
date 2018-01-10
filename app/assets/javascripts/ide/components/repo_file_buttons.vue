<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters([
      'activeFile',
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
  },
};
</script>

<template>
  <div
    v-if="showButtons"
    class="multi-file-editor-btn-group"
  >
    <a
      :href="activeFile.rawPath"
      target="_blank"
      class="btn btn-default btn-sm raw"
      rel="noopener noreferrer">
      {{ rawDownloadButtonLabel }}
    </a>

    <div
      class="btn-group"
      role="group"
      aria-label="File actions"
    >
      <a
        :href="activeFile.blamePath"
        class="btn btn-default btn-sm blame"
      >
        Blame
      </a>
      <a
        :href="activeFile.commitsPath"
        class="btn btn-default btn-sm history"
      >
        History
      </a>
      <a
        :href="activeFile.permalink"
        class="btn btn-default btn-sm permalink"
      >
        Permalink
      </a>
    </div>
  </div>
</template>

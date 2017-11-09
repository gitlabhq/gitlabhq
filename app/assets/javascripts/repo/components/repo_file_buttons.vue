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
    class="repo-file-buttons"
  >
    <a
      :href="activeFile.rawPath"
      target="_blank"
      class="btn btn-default raw"
      rel="noopener noreferrer">
      {{ rawDownloadButtonLabel }}
    </a>

    <div
      class="btn-group"
      role="group"
      aria-label="File actions">
      <a
        :href="activeFile.blamePath"
        class="btn btn-default blame">
        Blame
      </a>
      <a
        :href="activeFile.commitsPath"
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

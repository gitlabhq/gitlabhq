<script>
export default {
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showButtons() {
      return this.file.rawPath ||
        this.file.blamePath ||
        this.file.commitsPath ||
        this.file.permalink;
    },
    rawDownloadButtonLabel() {
      return this.file.binary ? 'Download' : 'Raw';
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
      :href="file.rawPath"
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
        :href="file.blamePath"
        class="btn btn-default btn-sm blame"
      >
        Blame
      </a>
      <a
        :href="file.commitsPath"
        class="btn btn-default btn-sm history"
      >
        History
      </a>
      <a
        :href="file.permalink"
        class="btn btn-default btn-sm permalink"
      >
        Permalink
      </a>
    </div>
  </div>
</template>

<script>
/* global LineHighlighter */
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters([
      'activeFile',
      'activeFileCurrentViewer',
      'activeFileHTML',
    ]),
    renderErrorTooLarge() {
      return this.activeFile.renderError === 'too_large';
    },
  },
  methods: {
    highlightFile() {
      $(this.$el).find('.file-content').syntaxHighlight();
    },
  },
  mounted() {
    this.highlightFile();
    this.lineHighlighter = new LineHighlighter({
      fileHolderSelector: '.blob-viewer-container',
      scrollFileHolder: true,
    });
  },
  updated() {
    this.$nextTick(() => {
      this.highlightFile();
    });
  },
};
</script>

<template>
<div class="blob-viewer-container">
  <div
    v-if="!activeFile.renderError"
    class="blob-full-height"
  >
    <div
      v-if="!activeFileCurrentViewer.loading"
      v-html="activeFileHTML"
      class="blob-full-height"
    >
    </div>
    <div
      v-else
      class="blob-viewer-container text-center prepend-top-default append-bottom-default"
    >
      <i
        aria-hidden="true"
        aria-label="Loading content..."
        class="fa fa-spinner fa-spin fa-2x"
      >
      </i>
    </div>
  </div>
  <div
    v-else-if="activeFile.tempFile"
    class="vertical-center render-error">
    <p class="text-center">
      The source could not be displayed for this temporary file.
    </p>
  </div>
  <div
    v-else-if="renderErrorTooLarge"
    class="vertical-center render-error">
    <p class="text-center">
      The source could not be displayed because it is too large. You can <a :href="activeFile.rawPath" download>download</a> it instead.
    </p>
  </div>
  <div
    v-else
    class="vertical-center render-error">
    <p class="text-center">
      The source could not be displayed because a rendering error occurred. You can <a :href="activeFile.rawPath" download>download</a> it instead.
    </p>
  </div>
</div>
</template>

<script>
/* global LineHighlighter */
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters([
      'activeFile',
    ]),
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
    v-html="activeFile.html">
  </div>
  <div
    v-else-if="activeFile.renderError == 'too_large'"
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

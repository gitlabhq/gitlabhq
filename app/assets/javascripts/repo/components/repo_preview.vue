<script>
/* global LineHighlighter */
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters([
      'activeFile',
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
    v-html="activeFile.html">
  </div>
  <div
    v-else-if="activeFile.tempFile"
    class="vertical-center render-error">
    <p class="text-center">
      The source could not be displayed for this temporary file.
    </p>
  </div>
  <div
<<<<<<< HEAD
<<<<<<< HEAD
    v-else-if="activeFile.tooLarge"
=======
    v-else-if="renderErrorTooLarge"
>>>>>>> e24d1890aea9c550e02d9145f50e8e1ae153a3a3
=======
    v-else-if="renderErrorTooLarge"
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571
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

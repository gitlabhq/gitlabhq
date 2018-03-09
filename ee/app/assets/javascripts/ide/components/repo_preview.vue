<script>
  import $ from 'jquery';
  import { mapGetters } from 'vuex';
  import LineHighlighter from '~/line_highlighter';
  import syntaxHighlight from '~/syntax_highlight';

  export default {
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
      renderErrorTooLarge() {
        return this.activeFile.renderError === 'too_large';
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
    methods: {
      highlightFile() {
        syntaxHighlight($(this.$el).find('.file-content'));
      },
    },
  };
</script>

<template>
  <div>
    <div
      v-if="!activeFile.renderError"
      v-html="activeFile.html"
      class="multi-file-preview-holder"
    >
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
        The source could not be displayed because it is too large.
        You can <a
          :href="activeFile.rawPath"
          download>download</a> it instead.
      </p>
    </div>
    <div
      v-else
      class="vertical-center render-error">
      <p class="text-center">
        The source could not be displayed because a rendering error occurred.
        You can <a
          :href="activeFile.rawPath"
          download>download</a> it instead.
      </p>
    </div>
  </div>
</template>

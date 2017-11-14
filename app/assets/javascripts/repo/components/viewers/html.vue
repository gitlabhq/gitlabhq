<script>
  import { mapGetters } from 'vuex';

  export default {
    computed: {
      ...mapGetters([
        'activeFile',
        'activeFileCurrentViewer',
        'activeFileHTML',
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
</template>

<script>
  /* global LineHighlighter */
  import { mapGetters } from 'vuex';
  import loadingIcon from '../../../vue_shared/components/loading_icon.vue';

  export default {
    name: 'HTMLViewer',
    components: {
      loadingIcon,
    },
    computed: {
      ...mapGetters([
        'activeFileCurrentViewer',
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
    class="blob-full-height"
  >
    <div
      v-if="!activeFileCurrentViewer.loading"
      v-html="activeFileCurrentViewer.html"
      class="blob-full-height"
    >
    </div>
    <div
      v-else
      class="blob-viewer-container text-center prepend-top-default append-bottom-default"
    >
      <loading-icon
        size="2"
      />
    </div>
  </div>
</template>

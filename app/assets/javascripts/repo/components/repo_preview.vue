<script>
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';

export default {
  data: {
    fileContentLoaded: false,
    allowRenderLargeFile: false,
  },
  props: {
    activeBlobViewers: { type: Object, required: true },
    activeBlobContent: { type: String, required: false },
  },
  computed: {
    richViewerDetails() {
      return this.activeBlobViewers.rich_viewer;
    },
    simpleViewerDetails() {
      return this.activeBlobViewers.simple_viewer;
    },
    canDisplayRichViewer() {
      // may need to be moved into higher level because it determine whether switcher should be shown
      return this.richViewerDetails !== null && this.simpleViewerDetails.name === 'text';
    },
    shouldDisplayRichViewer() {
      if (this.canDisplayRichViewer &&
    },
    currentBlobViewer() {
      return this.shouldDisplayRichViewer ? this.richViewerDetails : this.simpleViewerDetails;
    },
    largeFileIsCollapsed() {
      return this.currentBlobViewer.render_error === 'collapsed';
    },
    hasRenderError() {
      // allowRenderLargeFile needs to be reset when active file changes -- perhaps will need to store refs to files that have been allowed to render
      return this.currentBlobViewer.render_error !== null || (this.largeFileIsCollapsed && this.allowRenderLargeFile);
    },
    baseRenderErrorMessage() {
      const viewerTitle = this.currentBlobViewer.switcher_title;
      const errorReason = this.currentBlobViewer.render_error_reason;

      return `The ${viewerTitle} could not be displayed because ${errorReason}.`;
    },
    currentBlobRemoteURL() {
      return this.currentBlobViewer.path;
    },
    pathHasLineNumber() {
      const regex = /L[0-9]+(-[0-9+])?/
      return regex.match(this.currentBlobRemoteURL);
    }
  },

  methods: {
    highlightFile() {
      $(this.$el).find('.file-content').syntaxHighlight();
    },
    renderLargeFileAnyway() {
      this.allowRenderLargeFile = true;
    },
    navigateToLineNumber() {
      if (this.pathHasLineNumber) {
        this.$fileHolder.trigger('highlight:line')
        gl.utils.handleLocationHash(); // scrolls to the line
      }
    },
    renderGFM() {
      $(viewer).renderGFM(); // to render any GFM code blocks and Math blocks.
    },
    fetchBlobContent() {
      // this should pass activeBlobContent as a prop
      Helper.getContent(this.currentBlobRemoteURL)
        .then(() => {
          this.highlightFile();
          this.navigateToLineNumber();
          this.renderGFM();
        });
    }
  },

  watch: {
    activeBlobContent() {
      this.$nextTick(() => {
        this.highlightFile();
      });
    },
  },
  mounted() {
    if (!this.hasRenderError) {
      this.fetchBlobContent()
        .then(() => {
          this.fileContentLoaded = true;
        });
    }
  }
};
</script>

<template>
<div>
  <div
    v-if="!hasRenderError"
    v-html="activeBlobContent">
  </div>

  <div
    v-if='hasRenderError'
    class="vertical-center render-error">
    <p class="text-center">
      {{ this.baseRenderErrorMessage }} You can
      <span v-if="currentBlobViewer.render_error === 'collapsed'">
        <a href='#' @click='renderLargeFileAnyway'>load it anyway</a>
      </span>
      <span
        v-if="currentBlobViewer.type === 'rich' && simpleViewerDetails.name === 'text' && currentBlobViewer.render_error !== 'server_side_but_stored_externally">
        <a :href=''>view the source</a>
      </span>
      <span v-if="else">
        <a :href=''>download it</a>
      </span>
      instead.
    </p>
  </div>
</div>
</template>

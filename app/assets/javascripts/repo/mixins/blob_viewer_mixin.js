// expects precense of activeBlobViewers and selectedBlobViewerType
export default {
  computed: {
    richViewerDetails() {
      return this.activeBlobViewers.rich_viewer;
    },
    simpleViewerDetails() {
      return this.activeBlobViewers.simple_viewer;
    },
    canDisplayRichViewer() {
      return this.richViewerDetails !== null && this.simpleViewerDetails.name === 'text';
    },
    currentBlobViewer() {
      return this.selectedBlobViewerType === 'simple' ? this.simpleViewerDetails : this.richViewerDetails;
    },
    currentBlobViewerType() {
      return this.currentBlobViewer.type;
    },
    viewerIsRich() {
      return this.currentBlobViewerType === 'rich';
    },
    viewerIsSimple() {
      return this.currentBlobViewerType === 'simple';
    },
  },
};


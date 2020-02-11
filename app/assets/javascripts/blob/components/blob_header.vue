<script>
import ViewerSwitcher from './blob_header_viewer_switcher.vue';
import DefaultActions from './blob_header_default_actions.vue';
import BlobFilepath from './blob_header_filepath.vue';
import eventHub from '../event_hub';
import { RICH_BLOB_VIEWER, SIMPLE_BLOB_VIEWER } from './constants';

export default {
  components: {
    ViewerSwitcher,
    DefaultActions,
    BlobFilepath,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    hideDefaultActions: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideViewerSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      activeViewer: this.blob.richViewer ? RICH_BLOB_VIEWER : SIMPLE_BLOB_VIEWER,
    };
  },
  computed: {
    showViewerSwitcher() {
      return !this.hideViewerSwitcher && Boolean(this.blob.simpleViewer && this.blob.richViewer);
    },
    showDefaultActions() {
      return !this.hideDefaultActions;
    },
  },
  created() {
    if (this.showViewerSwitcher) {
      eventHub.$on('switch-viewer', this.setActiveViewer);
    }
  },
  beforeDestroy() {
    if (this.showViewerSwitcher) {
      eventHub.$off('switch-viewer', this.setActiveViewer);
    }
  },
  methods: {
    setActiveViewer(viewer) {
      this.activeViewer = viewer;
    },
  },
};
</script>
<template>
  <div class="js-file-title file-title-flex-parent">
    <blob-filepath :blob="blob">
      <template #filepathPrepend>
        <slot name="prepend"></slot>
      </template>
    </blob-filepath>

    <div class="file-actions d-none d-sm-block">
      <viewer-switcher v-if="showViewerSwitcher" :blob="blob" :active-viewer="activeViewer" />

      <slot name="actions"></slot>

      <default-actions v-if="showDefaultActions" :blob="blob" :active-viewer="activeViewer" />
    </div>
  </div>
</template>

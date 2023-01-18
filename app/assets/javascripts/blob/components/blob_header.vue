<script>
import DefaultActions from 'jh_else_ce/blob/components/blob_header_default_actions.vue';
import BlobFilepath from './blob_header_filepath.vue';
import ViewerSwitcher from './blob_header_viewer_switcher.vue';
import { SIMPLE_BLOB_VIEWER } from './constants';
import TableOfContents from './table_contents.vue';

export default {
  components: {
    ViewerSwitcher,
    DefaultActions,
    BlobFilepath,
    TableOfContents,
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
    isBinary: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeViewerType: {
      type: String,
      required: false,
      default: SIMPLE_BLOB_VIEWER,
    },
    hasRenderError: {
      type: Boolean,
      required: false,
      default: false,
    },
    showPath: {
      type: Boolean,
      required: false,
      default: true,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      viewer: this.hideViewerSwitcher ? null : this.activeViewerType,
    };
  },
  computed: {
    showViewerSwitcher() {
      return !this.hideViewerSwitcher && Boolean(this.blob.simpleViewer && this.blob.richViewer);
    },
    showDefaultActions() {
      return !this.hideDefaultActions;
    },
    isEmpty() {
      return this.blob.rawSize === '0';
    },
    blobSwitcherDocIcon() {
      return this.blob.richViewer?.fileType === 'csv' ? 'table' : 'document';
    },
  },
  watch: {
    viewer(newVal, oldVal) {
      if (!this.hideViewerSwitcher && newVal !== oldVal) {
        this.$emit('viewer-changed', newVal);
      }
    },
  },
  methods: {
    proxyCopyRequest() {
      this.$emit('copy');
    },
  },
};
</script>
<template>
  <div class="js-file-title file-title-flex-parent">
    <div class="gl-display-flex">
      <table-of-contents class="gl-pr-2" />
      <blob-filepath :blob="blob" :show-path="showPath">
        <template #filepath-prepend>
          <slot name="prepend"></slot>
        </template>
      </blob-filepath>
    </div>

    <div class="gl-display-flex gl-flex-wrap file-actions">
      <viewer-switcher v-if="showViewerSwitcher" v-model="viewer" :doc-icon="blobSwitcherDocIcon" />

      <slot name="actions"></slot>

      <default-actions
        v-if="showDefaultActions"
        :raw-path="blob.externalStorageUrl || blob.rawPath"
        :active-viewer="viewer"
        :has-render-error="hasRenderError"
        :is-binary="isBinary"
        :environment-name="blob.environmentFormattedExternalUrl"
        :environment-path="blob.environmentExternalUrlForRouteMap"
        :is-empty="isEmpty"
        :override-copy="overrideCopy"
        @copy="proxyCopyRequest"
      />
    </div>
  </div>
</template>

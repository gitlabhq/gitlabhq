<script>
import ViewerSwitcher from './blob_header_viewer_switcher.vue';
import DefaultActions from './blob_header_default_actions.vue';
import BlobFilepath from './blob_header_filepath.vue';
import { SIMPLE_BLOB_VIEWER } from './constants';

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
    <blob-filepath :blob="blob">
      <template #filepathPrepend>
        <slot name="prepend"></slot>
      </template>
    </blob-filepath>

    <div class="file-actions d-none d-sm-flex">
      <viewer-switcher v-if="showViewerSwitcher" v-model="viewer" />

      <slot name="actions"></slot>

      <default-actions
        v-if="showDefaultActions"
        :raw-path="blob.rawPath"
        :active-viewer="viewer"
        :has-render-error="hasRenderError"
        @copy="proxyCopyRequest"
      />
    </div>
  </div>
</template>

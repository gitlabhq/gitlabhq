<script>
import DefaultActions from 'jh_else_ce/blob/components/blob_header_default_actions.vue';
import BlobFilepath from './blob_header_filepath.vue';
import ViewerSwitcher from './blob_header_viewer_switcher.vue';
import { SIMPLE_BLOB_VIEWER, BLAME_VIEWER } from './constants';
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
    showPathAsLink: {
      type: Boolean,
      required: false,
      default: false,
    },
    overrideCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlameToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlobSize: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      viewer: this.hideViewerSwitcher ? null : this.activeViewerType,
    };
  },
  computed: {
    isEmpty() {
      return this.blob.rawSize === '0';
    },
  },
  watch: {
    viewer(newVal, oldVal) {
      if (newVal !== BLAME_VIEWER && newVal !== oldVal) {
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
    <div class="gl-mb-3 gl-flex gl-gap-3 md:gl-mb-0">
      <blob-filepath
        :blob="blob"
        :show-path="showPath"
        :show-as-link="showPathAsLink"
        :show-blob-size="showBlobSize"
      >
        <template #filepath-prepend>
          <slot name="prepend"></slot>
        </template>
      </blob-filepath>
    </div>

    <div class="file-actions gl-flex gl-flex-wrap gl-gap-3">
      <viewer-switcher
        v-if="!hideViewerSwitcher"
        v-model="viewer"
        :show-blame-toggle="showBlameToggle"
        :show-viewer-toggles="Boolean(blob.simpleViewer && blob.richViewer)"
        v-on="$listeners"
      />
      <table-of-contents class="gl-pr-2" />
      <slot name="ee-duo-workflow-action" data-test-id="ee-duo-workflow-action"></slot>

      <slot name="actions"></slot>

      <default-actions
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

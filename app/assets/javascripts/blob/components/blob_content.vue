<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';
import BlobContentError from './blob_content_error.vue';

import { BLOB_RENDER_EVENT_LOAD, BLOB_RENDER_EVENT_SHOW_SOURCE } from './constants';

export default {
  name: 'BlobContent',
  components: {
    GlLoadingIcon,
    BlobContentError,
  },
  props: {
    blob: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    content: {
      type: String,
      default: '',
      required: false,
    },
    isRawContent: {
      type: Boolean,
      default: false,
      required: false,
    },
    richViewer: {
      type: String,
      default: '',
      required: false,
    },
    loading: {
      type: Boolean,
      default: true,
      required: false,
    },
    activeViewer: {
      type: Object,
      required: true,
    },
  },
  computed: {
    viewer() {
      switch (this.activeViewer.type) {
        case 'rich':
          return RichViewer;
        default:
          return SimpleViewer;
      }
    },
    viewerError() {
      return this.activeViewer.renderError;
    },
  },
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
};
</script>
<template>
  <div class="blob-viewer" :data-type="activeViewer.type">
    <gl-loading-icon v-if="loading" size="md" color="dark" class="my-4 mx-auto" />

    <template v-else>
      <blob-content-error
        v-if="viewerError"
        :viewer-error="viewerError"
        :blob="blob"
        @[$options.BLOB_RENDER_EVENT_LOAD]="$emit($options.BLOB_RENDER_EVENT_LOAD)"
        @[$options.BLOB_RENDER_EVENT_SHOW_SOURCE]="$emit($options.BLOB_RENDER_EVENT_SHOW_SOURCE)"
      />
      <component
        :is="viewer"
        v-else
        ref="contentViewer"
        :content="content"
        :rich-viewer="richViewer"
        :is-raw-content="isRawContent"
        :file-name="blob.name"
        :type="activeViewer.fileType"
        data-qa-selector="file_content"
      />
    </template>
  </div>
</template>

<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';
import BlobContentError from './blob_content_error.vue';

export default {
  components: {
    GlLoadingIcon,
    BlobContentError,
  },
  props: {
    content: {
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
};
</script>
<template>
  <div class="blob-viewer" :data-type="activeViewer.type">
    <gl-loading-icon v-if="loading" size="md" color="dark" class="my-4 mx-auto" />

    <template v-else>
      <blob-content-error v-if="viewerError" :viewer-error="viewerError" />
      <component :is="viewer" v-else ref="contentViewer" :content="content" />
    </template>
  </div>
</template>

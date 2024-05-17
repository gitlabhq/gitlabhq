<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { RichViewer, SimpleViewer } from '~/vue_shared/components/blob_viewers';
import BlobContentError from './blob_content_error.vue';

import {
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
  RICH_BLOB_VIEWER,
} from './constants';

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
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    currentRef: {
      type: String,
      required: false,
      default: '',
    },
    content: {
      type: String,
      default: '',
      required: false,
    },
    showBlame: {
      type: Boolean,
      required: false,
      default: false,
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
    isBlameLinkHidden: {
      type: Boolean,
      required: false,
      default: false,
    },
    hideLineNumbers: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return { richContentLoaded: false };
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
    lineNumbers() {
      // rawTextBlob is used for source code files and content for snippets
      const content = this.blob?.rawTextBlob || this.content;

      return content?.split('\n')?.length || 0;
    },
    isContentLoaded() {
      return this.activeViewer.type === RICH_BLOB_VIEWER
        ? !this.loading && this.richContentLoaded
        : !this.loading;
    },
  },
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
};
</script>
<template>
  <div class="blob-viewer" :data-type="activeViewer.type" :data-loaded="isContentLoaded">
    <gl-loading-icon v-if="loading" size="lg" color="dark" class="my-4 mx-auto" />

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
        :current-ref="currentRef"
        :project-path="projectPath"
        :blob-path="blob.path || ''"
        :rich-viewer="richViewer"
        :is-raw-content="isRawContent"
        :show-blame="showBlame"
        :file-name="blob.name"
        :blame-path="blob.blamePath"
        :type="activeViewer.fileType"
        :line-numbers="lineNumbers"
        :is-blame-link-hidden="isBlameLinkHidden"
        :hide-line-numbers="hideLineNumbers"
        data-testid="blob-viewer-file-content"
        @richContentLoaded="richContentLoaded = true"
      />
    </template>
  </div>
</template>

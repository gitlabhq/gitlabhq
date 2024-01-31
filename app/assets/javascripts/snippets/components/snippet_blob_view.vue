<script>
import GetBlobContent from 'shared_queries/snippet/snippet_blob_content.query.graphql';

import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';

import {
  SIMPLE_BLOB_VIEWER,
  RICH_BLOB_VIEWER,
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
} from '~/blob/components/constants';

export default {
  components: {
    BlobHeader,
    BlobContent,
  },
  apollo: {
    blobContent: {
      query: GetBlobContent,
      variables() {
        return {
          ids: [this.snippet.id],
          rich: this.activeViewerType === RICH_BLOB_VIEWER,
          paths: [this.blob.path],
        };
      },
      update(data) {
        return this.onContentUpdate(data);
      },
      skip() {
        return this.viewer.renderError;
      },
    },
  },
  provide() {
    return {
      blobHash: Math.random().toString().split('.')[1],
    };
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      blobContent: '',
      activeViewerType:
        this.blob?.richViewer && !window.location.hash?.startsWith('#LC')
          ? RICH_BLOB_VIEWER
          : SIMPLE_BLOB_VIEWER,
    };
  },
  computed: {
    isContentLoading() {
      return this.$apollo.queries.blobContent.loading;
    },
    viewer() {
      const { richViewer, simpleViewer } = this.blob;
      return this.activeViewerType === RICH_BLOB_VIEWER ? richViewer : simpleViewer;
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
  },
  methods: {
    switchViewer(newViewer) {
      this.activeViewerType = newViewer || SIMPLE_BLOB_VIEWER;
    },
    forceQuery() {
      this.$apollo.queries.blobContent.skip = false;
      this.$apollo.queries.blobContent.refetch();
    },
    onContentUpdate(data) {
      const { path: blobPath } = this.blob;
      const {
        blobs: { nodes: dataBlobs },
      } = data.snippets.nodes[0];
      const updatedBlobData = dataBlobs.find((blob) => blob.path === blobPath);
      return updatedBlobData.richData || updatedBlobData.plainData;
    },
  },
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
};
</script>
<template>
  <figure class="file-holder snippet-file-content" :aria-label="__('Code snippet')">
    <blob-header
      :blob="blob"
      :active-viewer-type="viewer.type"
      :has-render-error="hasRenderError"
      @viewer-changed="switchViewer"
    />
    <blob-content
      is-blame-link-hidden
      :loading="isContentLoading"
      :content="blobContent"
      :active-viewer="viewer"
      :blob="blob"
      @[$options.BLOB_RENDER_EVENT_LOAD]="forceQuery"
      @[$options.BLOB_RENDER_EVENT_SHOW_SOURCE]="switchViewer"
    />
  </figure>
</template>

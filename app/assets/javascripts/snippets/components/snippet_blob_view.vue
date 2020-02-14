<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import { SNIPPET_VISIBILITY_PUBLIC } from '../constants';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobContent from '~/blob/components/blob_content.vue';
import { GlLoadingIcon } from '@gitlab/ui';

import GetSnippetBlobQuery from '../queries/snippet.blob.query.graphql';
import GetBlobContent from '../queries/snippet.blob.content.query.graphql';

import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';

export default {
  components: {
    BlobEmbeddable,
    BlobHeader,
    BlobContent,
    GlLoadingIcon,
  },
  apollo: {
    blob: {
      query: GetSnippetBlobQuery,
      variables() {
        return {
          ids: this.snippet.id,
        };
      },
      update: data => data.snippets.edges[0].node.blob,
      result(res) {
        const viewer = res.data.snippets.edges[0].node.blob.richViewer
          ? RICH_BLOB_VIEWER
          : SIMPLE_BLOB_VIEWER;
        this.switchViewer(viewer, true);
      },
    },
    blobContent: {
      query: GetBlobContent,
      variables() {
        return {
          ids: this.snippet.id,
          rich: this.activeViewerType === RICH_BLOB_VIEWER,
        };
      },
      update: data =>
        data.snippets.edges[0].node.blob.richData || data.snippets.edges[0].node.blob.plainData,
    },
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      blob: {},
      blobContent: '',
      activeViewerType: window.location.hash ? SIMPLE_BLOB_VIEWER : '',
    };
  },
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
    isBlobLoading() {
      return this.$apollo.queries.blob.loading;
    },
    isContentLoading() {
      return this.$apollo.queries.blobContent.loading;
    },
    viewer() {
      const { richViewer, simpleViewer } = this.blob;
      return this.activeViewerType === RICH_BLOB_VIEWER ? richViewer : simpleViewer;
    },
  },
  methods: {
    switchViewer(newViewer, respectHash = false) {
      this.activeViewerType = respectHash && window.location.hash ? SIMPLE_BLOB_VIEWER : newViewer;
    },
  },
};
</script>
<template>
  <div>
    <blob-embeddable v-if="embeddable" class="mb-3" :url="snippet.webUrl" />
    <gl-loading-icon
      v-if="isBlobLoading"
      :label="__('Loading blob')"
      size="lg"
      class="prepend-top-20 append-bottom-20"
    />
    <article v-else class="file-holder snippet-file-content">
      <blob-header :blob="blob" :active-viewer-type="viewer.type" @viewer-changed="switchViewer" />
      <blob-content :loading="isContentLoading" :content="blobContent" :active-viewer="viewer" />
    </article>
  </div>
</template>

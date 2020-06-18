<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import { SNIPPET_VISIBILITY_PUBLIC } from '../constants';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobContent from '~/blob/components/blob_content.vue';
import CloneDropdownButton from '~/vue_shared/components/clone_dropdown.vue';

import GetBlobContent from '../queries/snippet.blob.content.query.graphql';

import {
  SIMPLE_BLOB_VIEWER,
  RICH_BLOB_VIEWER,
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
} from '~/blob/components/constants';

export default {
  components: {
    BlobEmbeddable,
    BlobHeader,
    BlobContent,
    CloneDropdownButton,
  },
  apollo: {
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
      result() {
        if (this.activeViewerType === RICH_BLOB_VIEWER) {
          this.blob.richViewer.renderError = null;
        } else {
          this.blob.simpleViewer.renderError = null;
        }
      },
      skip() {
        return this.viewer.renderError;
      },
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
      blob: this.snippet.blob,
      blobContent: '',
      activeViewerType:
        this.snippet.blob?.richViewer && !window.location.hash
          ? RICH_BLOB_VIEWER
          : SIMPLE_BLOB_VIEWER,
    };
  },
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
    isContentLoading() {
      return this.$apollo.queries.blobContent.loading;
    },
    viewer() {
      const { richViewer, simpleViewer } = this.blob;
      return this.activeViewerType === RICH_BLOB_VIEWER ? richViewer : simpleViewer;
    },
    canBeCloned() {
      return this.snippet.sshUrlToRepo || this.snippet.httpUrlToRepo;
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
  },
  BLOB_RENDER_EVENT_LOAD,
  BLOB_RENDER_EVENT_SHOW_SOURCE,
};
</script>
<template>
  <div>
    <blob-embeddable v-if="embeddable" class="mb-3" :url="snippet.webUrl" />
    <article class="file-holder snippet-file-content">
      <blob-header
        :blob="blob"
        :active-viewer-type="viewer.type"
        :has-render-error="hasRenderError"
        @viewer-changed="switchViewer"
      >
        <template #actions>
          <clone-dropdown-button
            v-if="canBeCloned"
            class="mr-2"
            :ssh-link="snippet.sshUrlToRepo"
            :http-link="snippet.httpUrlToRepo"
            data-qa-selector="clone_button"
          />
        </template>
      </blob-header>
      <blob-content
        :loading="isContentLoading"
        :content="blobContent"
        :active-viewer="viewer"
        :blob="blob"
        @[$options.BLOB_RENDER_EVENT_LOAD]="forceQuery"
        @[$options.BLOB_RENDER_EVENT_SHOW_SOURCE]="switchViewer"
      />
    </article>
  </div>
</template>

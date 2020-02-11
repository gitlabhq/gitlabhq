<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import { SNIPPET_VISIBILITY_PUBLIC } from '../constants';
import BlobHeader from '~/blob/components/blob_header.vue';
import GetSnippetBlobQuery from '../queries/snippet.blob.query.graphql';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    BlobEmbeddable,
    BlobHeader,
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
    };
  },
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
    isBlobLoading() {
      return this.$apollo.queries.blob.loading;
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
      :size="2"
      class="prepend-top-20 append-bottom-20"
    />
    <article v-else class="file-holder snippet-file-content">
      <blob-header :blob="blob" />
    </article>
  </div>
</template>

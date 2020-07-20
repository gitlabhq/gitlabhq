<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import SnippetHeader from './snippet_header.vue';
import SnippetTitle from './snippet_title.vue';
import SnippetBlob from './snippet_blob_view.vue';
import { GlLoadingIcon } from '@gitlab/ui';

import { getSnippetMixin } from '../mixins/snippets';
import { SNIPPET_VISIBILITY_PUBLIC } from '~/snippets/constants';

export default {
  components: {
    BlobEmbeddable,
    SnippetHeader,
    SnippetTitle,
    GlLoadingIcon,
    SnippetBlob,
  },
  mixins: [getSnippetMixin],
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
  },
};
</script>
<template>
  <div class="js-snippet-view">
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 append-bottom-20"
    />
    <template v-else>
      <snippet-header :snippet="snippet" />
      <snippet-title :snippet="snippet" />
      <blob-embeddable v-if="embeddable" class="gl-mb-5" :url="snippet.webUrl" />
      <div v-for="blob in blobs" :key="blob.path">
        <snippet-blob :snippet="snippet" :blob="blob" />
      </div>
    </template>
  </div>
</template>

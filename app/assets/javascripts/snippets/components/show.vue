<script>
import SnippetHeader from './snippet_header.vue';
import SnippetTitle from './snippet_title.vue';
import SnippetBlob from './snippet_blob_view.vue';
import { GlLoadingIcon } from '@gitlab/ui';

import { getSnippetMixin } from '../mixins/snippets';

export default {
  components: {
    SnippetHeader,
    SnippetTitle,
    GlLoadingIcon,
    SnippetBlob,
  },
  mixins: [getSnippetMixin],
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
      <snippet-blob :snippet="snippet" />
    </template>
  </div>
</template>

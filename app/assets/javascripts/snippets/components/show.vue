<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import SnippetHeader from './snippet_header.vue';
import SnippetTitle from './snippet_title.vue';
import SnippetBlob from './snippet_blob_view.vue';
import CloneDropdownButton from '~/vue_shared/components/clone_dropdown.vue';
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
    CloneDropdownButton,
  },
  mixins: [getSnippetMixin],
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
    canBeCloned() {
      return Boolean(this.snippet.sshUrlToRepo || this.snippet.httpUrlToRepo);
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
      <div class="gl-display-flex gl-justify-content-end gl-mb-5">
        <blob-embeddable v-if="embeddable" class="gl-flex-fill-1" :url="snippet.webUrl" />
        <clone-dropdown-button
          v-if="canBeCloned"
          class="gl-ml-3"
          :ssh-link="snippet.sshUrlToRepo"
          :http-link="snippet.httpUrlToRepo"
          data-qa-selector="clone_button"
        />
      </div>
      <snippet-blob v-for="blob in blobs" :key="blob.path" :snippet="snippet" :blob="blob" />
    </template>
  </div>
</template>

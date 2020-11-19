<script>
import { GlLoadingIcon } from '@gitlab/ui';
import EmbedDropdown from './embed_dropdown.vue';
import SnippetHeader from './snippet_header.vue';
import SnippetTitle from './snippet_title.vue';
import SnippetBlob from './snippet_blob_view.vue';
import CloneDropdownButton from '~/vue_shared/components/clone_dropdown.vue';
import { SNIPPET_VISIBILITY_PUBLIC } from '~/snippets/constants';
import {
  SNIPPET_MARK_VIEW_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import eventHub from '~/blob/components/eventhub';

import { getSnippetMixin } from '../mixins/snippets';
import { markBlobPerformance } from '../utils/blob';

eventHub.$on(SNIPPET_MEASURE_BLOBS_CONTENT, markBlobPerformance);

export default {
  components: {
    EmbedDropdown,
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
  beforeCreate() {
    performanceMarkAndMeasure({ mark: SNIPPET_MARK_VIEW_APP_START });
  },
};
</script>
<template>
  <div class="js-snippet-view">
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 gl-mb-6"
    />
    <template v-else>
      <snippet-header :snippet="snippet" />
      <snippet-title :snippet="snippet" />
      <div class="gl-display-flex gl-justify-content-end gl-mb-5">
        <embed-dropdown
          v-if="embeddable"
          :url="snippet.webUrl"
          data-qa-selector="snippet_embed_dropdown"
        />
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

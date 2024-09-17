<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import eventHub from '~/blob/components/eventhub';
import {
  SNIPPET_MARK_VIEW_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { getSnippetMixin } from '../mixins/snippets';
import { markBlobPerformance } from '../utils/blob';
import SnippetBlob from './snippet_blob_view.vue';
import SnippetHeader from './snippet_header.vue';
import SnippetDescription from './snippet_description.vue';

eventHub.$on(SNIPPET_MEASURE_BLOBS_CONTENT, markBlobPerformance);

export default {
  components: {
    SnippetHeader,
    SnippetDescription,
    GlAlert,
    GlLoadingIcon,
    SnippetBlob,
  },
  mixins: [getSnippetMixin],
  computed: {
    hasUnretrievableBlobs() {
      return this.snippet.hasUnretrievableBlobs;
    },
  },
  beforeCreate() {
    performanceMarkAndMeasure({ mark: SNIPPET_MARK_VIEW_APP_START });
  },
};
</script>
<template>
  <div class="js-snippet-view gl-pt-3">
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 gl-mb-6"
    />
    <template v-else>
      <snippet-header :snippet="snippet" />
      <snippet-description :snippet="snippet" />
      <gl-alert v-if="hasUnretrievableBlobs" variant="danger" class="gl-mb-3" :dismissible="false">
        {{
          __(
            'WARNING: This snippet contains hidden files which might be used to mask malicious behavior. Exercise caution if cloning and executing code from this snippet.',
          )
        }}
      </gl-alert>
      <snippet-blob
        v-for="blob in blobs"
        :key="blob.path"
        :snippet="snippet"
        :blob="blob"
        class="project-highlight-puc gl-mt-5"
      />
    </template>
  </div>
</template>

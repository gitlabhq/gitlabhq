<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import eventHub from '~/blob/components/eventhub';
import {
  SNIPPET_MARK_VIEW_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { VISIBILITY_LEVEL_PUBLIC_STRING } from '~/visibility_level/constants';
import SnippetCodeDropdown from '~/vue_shared/components/code_dropdown/snippet_code_dropdown.vue';

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
    SnippetCodeDropdown,
  },
  mixins: [getSnippetMixin],
  computed: {
    embeddable() {
      return (
        this.snippet.visibilityLevel === VISIBILITY_LEVEL_PUBLIC_STRING && !this.isInPrivateProject
      );
    },
    isInPrivateProject() {
      const projectVisibility = this.snippet?.project?.visibility;
      const isLimitedVisibilityProject = projectVisibility !== VISIBILITY_LEVEL_PUBLIC_STRING;
      return projectVisibility ? isLimitedVisibilityProject : false;
    },
    canBeCloned() {
      return Boolean(this.snippet.sshUrlToRepo || this.snippet.httpUrlToRepo);
    },
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
  <div class="gl-pt-3 js-snippet-view">
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 gl-mb-6"
    />
    <template v-else>
      <snippet-header :snippet="snippet" />
      <snippet-description :snippet="snippet" />
      <div class="gl-display-flex gl-justify-content-end gl-mb-5">
        <snippet-code-dropdown
          v-if="canBeCloned"
          class="gl-ml-3"
          :ssh-link="snippet.sshUrlToRepo"
          :http-link="snippet.httpUrlToRepo"
          :url="snippet.webUrl"
          :embeddable="embeddable"
          data-testid="code-button"
        />
      </div>
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
        class="project-highlight-puc"
      />
    </template>
  </div>
</template>

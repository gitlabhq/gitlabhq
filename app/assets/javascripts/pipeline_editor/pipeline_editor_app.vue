<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import TextEditor from './components/text_editor.vue';

import getBlobContent from './graphql/queries/blob_content.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    TextEditor,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: false,
      default: null,
    },
    ciConfigPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: null,
      content: '',
    };
  },
  apollo: {
    content: {
      query: getBlobContent,
      variables() {
        return {
          projectPath: this.projectPath,
          path: this.ciConfigPath,
          ref: this.defaultBranch,
        };
      },
      update(data) {
        return data?.blobContent?.rawData;
      },
      error(error) {
        this.error = error;
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.content.loading;
    },
    errorMessage() {
      const { message: generalReason, networkError } = this.error ?? {};

      const { data } = networkError?.response ?? {};
      // 404 for missing file uses `message`
      // 400 for a missing ref uses `error`
      const networkReason = data?.message ?? data?.error;

      const reason = networkReason ?? generalReason ?? this.$options.i18n.unknownError;
      return sprintf(this.$options.i18n.errorMessageWithReason, { reason });
    },
  },
  i18n: {
    unknownError: __('Unknown Error'),
    errorMessageWithReason: s__('Pipelines|CI file could not be loaded: %{reason}'),
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <gl-alert v-if="error" :dismissible="false" variant="danger">{{ errorMessage }}</gl-alert>
    <div class="gl-mt-4">
      <gl-loading-icon v-if="loading" size="lg" />
      <text-editor v-else v-model="content" />
    </div>
  </div>
</template>

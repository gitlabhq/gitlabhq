<script>
import { GlLoadingIcon, GlAlert, GlTabs, GlTab } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import TextEditor from './components/text_editor.vue';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';

import getBlobContent from './graphql/queries/blob_content.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
    GlTabs,
    GlTab,
    TextEditor,
    PipelineGraph,
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
      editorIsReady: false,
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
    pipelineData() {
      // Note data will loaded as part of https://gitlab.com/gitlab-org/gitlab/-/issues/263141
      return {};
    },
  },
  i18n: {
    unknownError: __('Unknown Error'),
    errorMessageWithReason: s__('Pipelines|CI file could not be loaded: %{reason}'),
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <gl-alert v-if="error" :dismissible="false" variant="danger">{{ errorMessage }}</gl-alert>
    <div class="gl-mt-4">
      <gl-loading-icon v-if="loading" size="lg" />
      <div v-else class="file-editor">
        <gl-tabs>
          <!-- editor should be mounted when its tab is visible, so the container has a size -->
          <gl-tab :title="$options.i18n.tabEdit" :lazy="!editorIsReady">
            <!-- editor should be mounted only once, when the tab is displayed -->
            <text-editor v-model="content" @editor-ready="editorIsReady = true" />
          </gl-tab>

          <gl-tab :title="$options.i18n.tabGraph">
            <pipeline-graph :pipeline-data="pipelineData" />
          </gl-tab>
        </gl-tabs>
      </div>
    </div>
  </div>
</template>

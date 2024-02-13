<script>
import { GlButton, GlSprintf, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';

export default {
  components: {
    GlButton,
    GlSprintf,
    GlEmptyState,
    PipelineEditorFileNav,
  },
  i18n: {
    title: __('Optimize your workflow with CI/CD Pipelines'),
    body: __(
      'Create a new %{codeStart}.gitlab-ci.yml%{codeEnd} file at the root of the repository to get started.',
    ),
    btnText: __('Configure pipeline'),
    externalCiNote: __("This project's pipeline configuration is located outside this repository"),
    externalCiInstructions: __(
      'To edit the pipeline configuration, you must go to the project or external site that hosts the file.',
    ),
  },
  inject: {
    emptyStateIllustrationPath: {
      default: '',
    },
    usesExternalConfig: {
      default: false,
      type: Boolean,
      required: false,
    },
  },
  methods: {
    createEmptyConfigFile() {
      this.$emit('createEmptyConfigFile');
    },
  },
};
</script>
<template>
  <div>
    <pipeline-editor-file-nav v-on="$listeners" />
    <gl-empty-state
      v-if="usesExternalConfig"
      :title="$options.i18n.externalCiNote"
      :description="$options.i18n.externalCiInstructions"
      :svg-path="emptyStateIllustrationPath"
    />

    <gl-empty-state v-else :title="$options.i18n.title" :svg-path="emptyStateIllustrationPath">
      <template #description>
        <gl-sprintf :message="$options.i18n.body">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </template>
      <template #actions>
        <gl-button
          variant="confirm"
          class="gl-mt-3"
          data-testid="create-new-ci-button"
          @click="createEmptyConfigFile"
        >
          {{ $options.i18n.btnText }}
        </gl-button>
      </template>
    </gl-empty-state>
  </div>
</template>

<script>
import { GlButton, GlSprintf, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

export default {
  components: {
    GlButton,
    GlSprintf,
    GlEmptyState,
    PipelineEditorFileNav,
    ExternalConfigEmptyState,
  },
  i18n: {
    title: __('Configure a pipeline to automate your builds, tests, and deployments'),
    body: __(
      'Create a %{codeStart}.gitlab-ci.yml%{codeEnd} file in your repository to configure and run your first pipeline.',
    ),
    btnText: __('Configure pipeline'),
  },
  inject: ['emptyStateIllustrationPath', 'usesExternalConfig', 'newPipelinePath'],
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
    <external-config-empty-state v-if="usesExternalConfig" :new-pipeline-path="newPipelinePath" />

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

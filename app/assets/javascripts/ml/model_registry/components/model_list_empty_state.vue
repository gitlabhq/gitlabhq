<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-dag-md.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    GlEmptyState,
    ClipboardButton,
    GlButton,
  },
  inject: ['mlflowTrackingUrl'],
  title: s__('MlModelRegistry|No models registered'),
  description: s__(
    'MlModelRegistry|Import your machine learning using GitLab directly or using the MLflow client:',
  ),
  createNew: s__('MlModelRegistry|Create model'),
  mlflowDocs: s__('MlModelRegistry|MLflow compatibility'),
  helpPath: helpPagePath('user/project/ml/model_registry/index', {
    anchor: 'creating-machine-learning-models-and-model-versions',
  }),
  emptySvgPath: emptySvgUrl,
  computed: {
    mlflowCommand() {
      return [
        // eslint-disable-next-line @gitlab/require-i18n-strings
        'import os',
        'from mlflow import MlflowClient',
        '',
        `os.environ["MLFLOW_TRACKING_URI"] = "${this.mlflowTrackingUrl}"`,
        'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
        '',
        s__('MlModelRegistry|# Create a model'),
        'client = MlflowClient()',
        "model_name = '<your_model_name>'",
        // eslint-disable-next-line @gitlab/require-i18n-strings
        "description = 'Model description'",
        'model = client.create_registered_model(model_name, description=description)',
        '',
        s__('MlModelRegistry|# Create a version'),
        'tags = { "gitlab.version": version }',
        'model_version = client.create_model_version(model_name, version, tags=tags)',
        '',
        s__('MlModelRegistry|# Log artifacts'),
        'client.log_artifact(run_id, \'<local/path/to/file.txt>\', artifact_path="")',
      ].join('\n');
    },
  },
  methods: {
    emitOpenCreateModel() {
      this.$emit('open-create-model');
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.title"
    :svg-path="$options.emptySvgPath"
    :svg-height="null"
    class="gl-py-8"
  >
    <template #description>
      <p>{{ $options.description }}</p>
      <pre
        class="code highlight gl-flex gl-border-none gl-text-left gl-p-2"
        data-testid="preview-code"
      >
        <code>{{ mlflowCommand }}</code>
        <clipboard-button
          category="tertiary"
          :text="mlflowCommand"
          class="gl-self-start"
          :title="__('Copy')"
        />
      </pre>
    </template>

    <template #actions>
      <gl-button variant="confirm" class="gl-mx-2 gl-mb-3" @click="emitOpenCreateModel">{{
        $options.createNew
      }}</gl-button>
      <gl-button class="gl-mb-3 gl-mr-3 gl-mx-2" :href="$options.helpPath"
        >{{ $options.mlflowDocs }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>

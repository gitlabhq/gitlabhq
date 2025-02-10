<script>
import { GlModal } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';

export default {
  components: {
    GlModal,
  },
  inject: ['mlflowTrackingUrl'],
  computed: {
    instructions() {
      return [
        {
          label: s__('MlModelRegistry|Setting up the client'),
          cmd: [
            // eslint-disable-next-line @gitlab/require-i18n-strings
            'import os',
            'from mlflow import MlflowClient',
            '',
            `os.environ["MLFLOW_TRACKING_URI"] = "${this.mlflowTrackingUrl}"`,
            'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
            '',
            'client = MlflowClient()',
          ].join('\n'),
        },
        {
          label: s__('MlModelRegistry|Creating a model'),
          cmd: [
            "model_name = '<your_model_name>'",
            // eslint-disable-next-line @gitlab/require-i18n-strings
            "description = 'Model description'",
            'model = client.create_registered_model(model_name, description=description)',
          ].join('\n'),
        },
        {
          label: s__('MlModelRegistry|Creating a model version'),
          cmd: [
            'tags = { "gitlab.version": version }',
            'model_version = client.create_model_version(model_name, version, tags=tags)',
          ].join('\n'),
        },
        {
          label: s__('MlModelRegistry|Logging artifacts'),
          cmd: [
            'run_id = model_version.run_id',
            'client.log_artifact(run_id, \'<local/path/to/file.txt>\', artifact_path="")',
          ].join('\n'),
        },
      ];
    },
  },
  methods: {
    openDocs() {
      visitUrl(
        helpPagePath('user/project/ml/model_registry/_index', {
          anchor: 'create-machine-learning-models-and-model-versions-by-using-mlflow',
        }),
        true,
      );
    },
  },
  modal: {
    title: s__('MlModelRegistry|Using the MLflow client'),
    id: MLFLOW_USAGE_MODAL_ID,
    firstLine: s__(
      'MlModelRegistry|Creating models, model versions and runs is also possible using the MLflow client:',
    ),
    actionPrimary: {
      text: s__('MlModelRegistry|MLflow compatibility documentation'),
      attributes: {
        variant: 'confirm',
      },
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modal.id"
    :title="$options.modal.title"
    :action-primary="$options.modal.actionPrimary"
    @primary="openDocs"
  >
    <p>{{ $options.modal.firstLine }}</p>

    <template v-for="instruction in instructions">
      <div :key="instruction.label">
        <label> {{ instruction.label }}</label>

        <pre
          class="code highlight gl-flex gl-border-none gl-p-2 gl-text-left gl-font-monospace"
          data-testid="preview-code"
        >
          <code class="gl-grow">{{ instruction.cmd }}</code>
        </pre>
      </div>
    </template>
  </gl-modal>
</template>

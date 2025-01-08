<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { CREATE_EXPERIMENT_HELP_PATH, MLFLOW_USAGE_MODAL_ID } from '../constants';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    ClipboardButton,
  },
  inject: ['mlflowTrackingUrl'],
  computed: {
    instruction() {
      return {
        label: s__('MlExperimentTracking|Creating an experiment'),
        cmd: [
          // eslint-disable-next-line @gitlab/require-i18n-strings
          'import os',
          'from mlflow import MlflowClient',
          '',
          `os.environ["MLFLOW_TRACKING_URI"] = "${this.mlflowTrackingUrl}"`,
          'os.environ["MLFLOW_TRACKING_TOKEN"] = <your_gitlab_token>',
          '',
          'client = MlflowClient()',
          '',
          `client.create_experiment(name="<your_experiment_name>", tags={'key': 'value'})`,
        ].join('\n'),
      };
    },
  },
  methods: {
    copyInstructions() {
      navigator.clipboard.writeText(this.instruction.cmd);
    },
  },
  MLFLOW_USAGE_MODAL_ID,
  CREATE_EXPERIMENT_HELP_PATH,
};
</script>

<template>
  <gl-modal
    :modal-id="$options.MLFLOW_USAGE_MODAL_ID"
    :title="s__('MlExperimentTracking|Using the MLflow client')"
    hide-footer
    no-focus-on-show
  >
    <p>{{ s__('MlExperimentTracking|Creating experiments using the MLflow client:') }}</p>

    <div :key="instruction.label">
      <label> {{ instruction.label }}</label>

      <pre
        class="code highlight gl-flex gl-border-none gl-p-2 gl-text-left gl-font-monospace"
        data-testid="preview-code"
      >
        <code class="gl-grow">{{ instruction.cmd }}</code>
        <clipboard-button
          category="tertiary"
          :text="instruction.cmd"
          :title="__('Copy to clipboard')"
          @click="copyInstructions"
        />
      </pre>
    </div>

    <p>
      <gl-sprintf
        :message="
          s__(
            'MlExperimentTracking|To learn more about MLflow client compatibility, see %{linkStart}the documentation%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.CREATE_EXPERIMENT_HELP_PATH" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>

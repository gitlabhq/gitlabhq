<script>
import { GlEmptyState } from '@gitlab/ui';
import Experiment from '~/experimentation/components/experiment.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import PipelinesCiTemplates from './pipelines_ci_templates.vue';

export default {
  i18n: {
    title: s__('Pipelines|Build with confidence'),
    description: s__(`Pipelines|GitLab CI/CD can automatically build,
      test, and deploy your code. Let GitLab take care of time
      consuming tasks, so you can spend more time creating.`),
    btnText: s__('Pipelines|Get started with CI/CD'),
    noCiDescription: s__('Pipelines|This project is not currently set up to run pipelines.'),
  },
  name: 'PipelinesEmptyState',
  components: {
    GlEmptyState,
    Experiment,
    PipelinesCiTemplates,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    canSetCi: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ciHelpPagePath() {
      return helpPagePath('ci/quick_start/index.md');
    },
  },
};
</script>
<template>
  <div>
    <experiment name="pipeline_empty_state_templates">
      <template #control>
        <gl-empty-state
          v-if="canSetCi"
          :title="$options.i18n.title"
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.description"
          :primary-button-text="$options.i18n.btnText"
          :primary-button-link="ciHelpPagePath"
        />
        <gl-empty-state
          v-else
          title=""
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.noCiDescription"
        />
      </template>
      <template #candidate>
        <pipelines-ci-templates />
      </template>
    </experiment>
  </div>
</template>

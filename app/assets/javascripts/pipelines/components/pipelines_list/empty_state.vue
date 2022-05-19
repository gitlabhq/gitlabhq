<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import PipelinesCiTemplates from './empty_state/pipelines_ci_templates.vue';
import IosTemplates from './empty_state/ios_templates.vue';

export default {
  i18n: {
    noCiDescription: s__('Pipelines|This project is not currently set up to run pipelines.'),
  },
  name: 'PipelinesEmptyState',
  components: {
    GlEmptyState,
    GitlabExperiment,
    PipelinesCiTemplates,
    IosTemplates,
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
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>
<template>
  <div>
    <gitlab-experiment v-if="canSetCi" name="ios_specific_templates">
      <template #control>
        <pipelines-ci-templates />
      </template>
      <template #candidate>
        <ios-templates :registration-token="registrationToken" />
      </template>
    </gitlab-experiment>
    <gl-empty-state
      v-else
      title=""
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.noCiDescription"
    />
  </div>
</template>

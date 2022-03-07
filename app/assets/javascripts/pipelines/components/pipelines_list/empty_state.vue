<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { startCodeQualityWalkthrough, track } from '~/code_quality_walkthrough/utils';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { getExperimentData } from '~/experimentation/utils';
import { s__ } from '~/locale';
import PipelinesCiTemplates from './pipelines_ci_templates.vue';

export default {
  i18n: {
    codeQualityTitle: s__('Pipelines|Improve code quality with GitLab CI/CD'),
    codeQualityDescription: s__(`Pipelines|To keep your codebase simple,
      readable, and accessible to contributors, use GitLab CI/CD
      to analyze your code quality with every push to your project.`),
    codeQualityBtnText: s__('Pipelines|Add a code quality job'),
    noCiDescription: s__('Pipelines|This project is not currently set up to run pipelines.'),
  },
  name: 'PipelinesEmptyState',
  components: {
    GlEmptyState,
    GlButton,
    GitlabExperiment,
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
    codeQualityPagePath: {
      type: String,
      required: false,
      default: null,
    },
    ciRunnerSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    anyRunnersAvailable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    isCodeQualityExperimentActive() {
      return this.canSetCi && Boolean(getExperimentData('code_quality_walkthrough'));
    },
  },
  mounted() {
    startCodeQualityWalkthrough();
  },
  methods: {
    trackClick() {
      track('cta_clicked');
    },
  },
};
</script>
<template>
  <div>
    <gitlab-experiment v-if="isCodeQualityExperimentActive" name="code_quality_walkthrough">
      <template #control><pipelines-ci-templates /></template>
      <template #candidate>
        <gl-empty-state
          :title="$options.i18n.codeQualityTitle"
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.codeQualityDescription"
        >
          <template #actions>
            <gl-button :href="codeQualityPagePath" variant="confirm" @click="trackClick()">
              {{ $options.i18n.codeQualityBtnText }}
            </gl-button>
          </template>
        </gl-empty-state>
      </template>
    </gitlab-experiment>
    <pipelines-ci-templates
      v-else-if="canSetCi"
      :ci-runner-settings-path="ciRunnerSettingsPath"
      :any-runners-available="anyRunnersAvailable"
    />
    <gl-empty-state
      v-else
      title=""
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.noCiDescription"
    />
  </div>
</template>

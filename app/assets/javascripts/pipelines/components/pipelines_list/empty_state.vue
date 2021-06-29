<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { startCodeQualityWalkthrough, track } from '~/code_quality_walkthrough/utils';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { getExperimentData } from '~/experimentation/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import PipelinesCiTemplates from './pipelines_ci_templates.vue';

export default {
  i18n: {
    title: s__('Pipelines|Build with confidence'),
    description: s__(`Pipelines|GitLab CI/CD can automatically build,
      test, and deploy your code. Let GitLab take care of time
      consuming tasks, so you can spend more time creating.`),
    aboutRunnersBtnText: s__('Pipelines|Learn about Runners'),
    installRunnersBtnText: s__('Pipelines|Install GitLab Runners'),
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
  },
  computed: {
    ciHelpPagePath() {
      return helpPagePath('ci/quick_start/index.md');
    },
    isCodeQualityExperimentActive() {
      return this.canSetCi && Boolean(getExperimentData('code_quality_walkthrough'));
    },
    isCiRunnerTemplatesExperimentActive() {
      return this.canSetCi && Boolean(getExperimentData('ci_runner_templates'));
    },
  },
  mounted() {
    startCodeQualityWalkthrough();
  },
  methods: {
    trackClick() {
      track('cta_clicked');
    },
    trackCiRunnerTemplatesClick(action) {
      const tracking = new ExperimentTracking('ci_runner_templates');
      tracking.event(action);
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
    <gitlab-experiment v-else-if="isCiRunnerTemplatesExperimentActive" name="ci_runner_templates">
      <template #control><pipelines-ci-templates /></template>
      <template #candidate>
        <gl-empty-state
          :title="$options.i18n.title"
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.description"
        >
          <template #actions>
            <gl-button
              :href="ciRunnerSettingsPath"
              variant="confirm"
              @click="trackCiRunnerTemplatesClick('install_runners_button_clicked')"
            >
              {{ $options.i18n.installRunnersBtnText }}
            </gl-button>
            <gl-button
              :href="ciHelpPagePath"
              variant="default"
              @click="trackCiRunnerTemplatesClick('learn_button_clicked')"
            >
              {{ $options.i18n.aboutRunnersBtnText }}
            </gl-button>
          </template>
        </gl-empty-state>
      </template>
    </gitlab-experiment>
    <pipelines-ci-templates v-else-if="canSetCi" />
    <gl-empty-state
      v-else
      title=""
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.noCiDescription"
    />
  </div>
</template>

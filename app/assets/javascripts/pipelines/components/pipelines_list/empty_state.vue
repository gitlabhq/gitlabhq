<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { startCodeQualityWalkthrough, track } from '~/code_quality_walkthrough/utils';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
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
    btnText: s__('Pipelines|Get started with CI/CD'),
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
  },
  computed: {
    ciHelpPagePath() {
      return helpPagePath('ci/quick_start/index.md');
    },
    isPipelineEmptyStateTemplatesExperimentActive() {
      return this.canSetCi && Boolean(getExperimentData('pipeline_empty_state_templates'));
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
    <gitlab-experiment
      v-if="isPipelineEmptyStateTemplatesExperimentActive"
      name="pipeline_empty_state_templates"
    >
      <template #control>
        <gl-empty-state
          :title="$options.i18n.title"
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.description"
          :primary-button-text="$options.i18n.btnText"
          :primary-button-link="ciHelpPagePath"
        />
      </template>
      <template #candidate>
        <pipelines-ci-templates />
      </template>
    </gitlab-experiment>
    <gitlab-experiment v-else-if="canSetCi" name="code_quality_walkthrough">
      <template #control>
        <gl-empty-state
          :title="$options.i18n.title"
          :svg-path="emptyStateSvgPath"
          :description="$options.i18n.description"
        >
          <template #actions>
            <gl-button :href="ciHelpPagePath" variant="confirm" @click="trackClick()">
              {{ $options.i18n.btnText }}
            </gl-button>
          </template>
        </gl-empty-state>
      </template>
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
    <gl-empty-state
      v-else
      title=""
      :svg-path="emptyStateSvgPath"
      :description="$options.i18n.noCiDescription"
    />
  </div>
</template>

<script>
import { GlProgressBar, GlSprintf } from '@gitlab/ui';
import { pick } from 'lodash';
import { s__ } from '~/locale';
import { ACTION_LABELS } from '../constants';
import LearnGitlabInfoCard from './learn_gitlab_info_card.vue';

export default {
  components: { LearnGitlabInfoCard, GlProgressBar, GlSprintf },
  i18n: {
    title: s__('LearnGitLab|Learn GitLab'),
    description: s__(
      'LearnGitLab|Ready to get started with GitLab? Follow these steps to set up your workspace, plan and commit changes, and deploy your project.',
    ),
    percentageCompleted: s__(`LearnGitLab|%{percentage}%{percentSymbol} completed`),
    workspace: {
      title: s__('LearnGitLab|Set up your workspace'),
      description: s__(
        "LearnGitLab|Complete these tasks first so you can enjoy GitLab's features to their fullest:",
      ),
    },
    plan: {
      title: s__('LearnGitLab|Plan and execute'),
      description: s__(
        'LearnGitLab|Create a workflow for your new workspace, and learn how GitLab features work together:',
      ),
    },
    deploy: {
      title: s__('LearnGitLab|Deploy'),
      description: s__(
        'LearnGitLab|Use your new GitLab workflow to deploy your application, monitor its health, and keep it secure:',
      ),
    },
  },
  props: {
    actions: {
      required: true,
      type: Object,
    },
  },
  maxValue: Object.keys(ACTION_LABELS).length,
  methods: {
    infoProps(action) {
      return {
        ...this.actions[action],
        ...pick(ACTION_LABELS[action], ['title', 'actionLabel', 'description', 'trialRequired']),
      };
    },
    progressValue() {
      return Object.values(this.actions).filter((a) => a.completed).length;
    },
    progressPercentage() {
      return Math.round((this.progressValue() / this.$options.maxValue) * 100);
    },
  },
};
</script>
<template>
  <div>
    <div class="row">
      <div class="gl-mb-7 col-md-8 col-lg-7">
        <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
        <p class="gl-text-gray-700 gl-mb-0">{{ $options.i18n.description }}</p>
      </div>
    </div>

    <div class="gl-mb-3">
      <p class="gl-text-gray-500 gl-mb-2" data-testid="completion-percentage">
        <gl-sprintf :message="$options.i18n.percentageCompleted">
          <template #percentage>{{ progressPercentage() }}</template>
          <template #percentSymbol>%</template>
        </gl-sprintf>
      </p>
      <gl-progress-bar :value="progressValue()" :max="$options.maxValue" />
    </div>

    <h2 class="gl-font-lg gl-mb-3">{{ $options.i18n.workspace.title }}</h2>
    <p class="gl-text-gray-700 gl-mb-6">{{ $options.i18n.workspace.description }}</p>

    <div class="row row-cols-2 row-cols-md-3 row-cols-lg-4">
      <div class="col gl-mb-6"><learn-gitlab-info-card v-bind="infoProps('userAdded')" /></div>
      <div class="col gl-mb-6"><learn-gitlab-info-card v-bind="infoProps('gitWrite')" /></div>
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('pipelineCreated')" />
      </div>
      <div class="col gl-mb-6"><learn-gitlab-info-card v-bind="infoProps('trialStarted')" /></div>
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('codeOwnersEnabled')" />
      </div>
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('requiredMrApprovalsEnabled')" />
      </div>
    </div>

    <h2 class="gl-font-lg gl-mb-3">{{ $options.i18n.plan.title }}</h2>
    <p class="gl-text-gray-700 gl-mb-6">{{ $options.i18n.plan.description }}</p>

    <div class="row row-cols-2 row-cols-md-3 row-cols-lg-4">
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('issueCreated')" />
      </div>
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('mergeRequestCreated')" />
      </div>
    </div>

    <h2 class="gl-font-lg gl-mb-3">{{ $options.i18n.deploy.title }}</h2>
    <p class="gl-text-gray-700 gl-mb-6">{{ $options.i18n.deploy.description }}</p>

    <div class="row row-cols-2 row-cols-lg-4 g-2 g-lg-3">
      <div class="col gl-mb-6">
        <learn-gitlab-info-card v-bind="infoProps('securityScanEnabled')" />
      </div>
    </div>
  </div>
</template>

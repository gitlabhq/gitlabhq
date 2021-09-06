<script>
import { GlProgressBar, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTION_LABELS, ACTION_SECTIONS } from '../constants';
import LearnGitlabSectionCard from './learn_gitlab_section_card.vue';

export default {
  components: { GlProgressBar, GlSprintf, LearnGitlabSectionCard },
  i18n: {
    title: s__('LearnGitLab|Learn GitLab'),
    description: s__(
      'LearnGitLab|Ready to get started with GitLab? Follow these steps to set up your workspace, plan and commit changes, and deploy your project.',
    ),
    percentageCompleted: s__(`LearnGitLab|%{percentage}%{percentSymbol} completed`),
  },
  props: {
    actions: {
      required: true,
      type: Object,
    },
    sections: {
      required: true,
      type: Object,
    },
  },
  maxValue: Object.keys(ACTION_LABELS).length,
  actionSections: Object.keys(ACTION_SECTIONS),
  computed: {
    progressValue() {
      return Object.values(this.actions).filter((a) => a.completed).length;
    },
    progressPercentage() {
      return Math.round((this.progressValue / this.$options.maxValue) * 100);
    },
  },
  methods: {
    actionsFor(section) {
      const actions = Object.fromEntries(
        Object.entries(this.actions).filter(
          ([action]) => ACTION_LABELS[action].section === section,
        ),
      );
      return actions;
    },
    svgFor(section) {
      return this.sections[section].svg;
    },
  },
};
</script>
<template>
  <div>
    <div class="row">
      <div class="gl-mb-7 gl-ml-5">
        <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
        <p class="gl-text-gray-700 gl-mb-0">{{ $options.i18n.description }}</p>
      </div>
    </div>
    <div class="gl-mb-3">
      <p class="gl-text-gray-500 gl-mb-2" data-testid="completion-percentage">
        <gl-sprintf :message="$options.i18n.percentageCompleted">
          <template #percentage>{{ progressPercentage }}</template>
          <template #percentSymbol>%</template>
        </gl-sprintf>
      </p>
      <gl-progress-bar :value="progressValue" :max="$options.maxValue" />
    </div>
    <div class="row row-cols-1 row-cols-md-3 gl-mt-5">
      <div v-for="section in $options.actionSections" :key="section" class="col gl-mb-6">
        <learn-gitlab-section-card
          :section="section"
          :svg="svgFor(section)"
          :actions="actionsFor(section)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { GlCard } from '@gitlab/ui';
import { ACTION_LABELS, ACTION_SECTIONS } from '../constants';

import LearnGitlabSectionLink from './learn_gitlab_section_link.vue';

export default {
  name: 'LearnGitlabSectionCard',
  components: { GlCard, LearnGitlabSectionLink },
  i18n: {
    ...ACTION_SECTIONS,
  },
  props: {
    section: {
      required: true,
      type: String,
    },
    svg: {
      required: true,
      type: String,
    },
    actions: {
      required: true,
      type: Object,
    },
  },
  computed: {
    sortedActions() {
      return Object.entries(this.actions).sort(
        (a1, a2) => ACTION_LABELS[a1[0]].position - ACTION_LABELS[a2[0]].position,
      );
    },
  },
};
</script>
<template>
  <gl-card class="gl-pt-0 learn-gitlab-section-card">
    <div class="learn-gitlab-section-card-header">
      <img :src="svg" />
      <h2 class="gl-font-lg gl-mb-3">{{ $options.i18n[section].title }}</h2>
      <p class="gl-text-gray-700 gl-mb-6">{{ $options.i18n[section].description }}</p>
    </div>
    <learn-gitlab-section-link
      v-for="[action, value] in sortedActions"
      :key="action"
      :action="action"
      :value="value"
    />
  </gl-card>
</template>

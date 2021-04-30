<script>
import { GlLink, GlCard, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'LearnGitlabInfoCard',
  components: { GlLink, GlCard, GlIcon },
  i18n: {
    trial: s__('Learn GitLab|Trial only'),
  },
  props: {
    title: {
      required: true,
      type: String,
    },
    description: {
      required: true,
      type: String,
    },
    actionLabel: {
      required: true,
      type: String,
    },
    url: {
      required: true,
      type: String,
    },
    completed: {
      required: true,
      type: Boolean,
    },
    svg: {
      required: true,
      type: String,
    },
    trialRequired: {
      default: false,
      required: false,
      type: Boolean,
    },
  },
};
</script>
<template>
  <gl-card class="gl-pt-0">
    <div class="gl-text-right gl-h-5">
      <gl-icon
        v-if="completed"
        name="check-circle-filled"
        class="gl-text-green-500"
        :size="16"
        data-testid="completed-icon"
      />
      <span
        v-else-if="trialRequired"
        class="gl-text-gray-500 gl-font-sm gl-font-style-italic"
        data-testid="trial-only"
        >{{ $options.i18n.trial }}</span
      >
    </div>
    <div
      class="gl-text-center gl-display-flex gl-justify-content-center gl-align-items-center gl-flex-direction-column learn-gitlab-info-card-content"
    >
      <img :src="svg" :alt="actionLabel" />
      <h6>{{ title }}</h6>
      <p class="gl-font-sm gl-text-gray-700">{{ description }}</p>
      <gl-link
        :href="url"
        target="_blank"
        rel="noopener noreferrer"
        data-track-action="click_link"
        :data-track-label="actionLabel"
        data-track-property="Growth::Activation::Experiment::LearnGitLabB"
        >{{ actionLabel }}</gl-link
      >
    </div>
  </gl-card>
</template>

<script>
import { GlAlert, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    titleLabel: __('Machine Learning Experiment Tracking is in Incubating Phase'),
    contentLabel: __(
      'GitLab incubates features to explore new use cases. These features are updated regularly, and support is limited',
    ),
    learnMoreLabel: __('Learn More'),
    feedbackLabel: __('Feedback and Updates'),
  },
  name: 'MlopsIncubationAlert',
  components: { GlAlert, GlLink },
  data() {
    return {
      isAlertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return !this.isAlertDismissed;
    },
  },
  methods: {
    dismissAlert() {
      this.isAlertDismissed = true;
    },
  },
};
</script>

<template>
  <gl-alert
    v-if="shouldShowAlert"
    :title="$options.i18n.titleLabel"
    variant="warning"
    :primary-button-text="$options.i18n.feedbackLabel"
    primary-button-link="https://gitlab.com/groups/gitlab-org/-/epics/8560"
    @dismiss="dismissAlert"
  >
    {{ $options.i18n.contentLabel }}
    <gl-link href="https://about.gitlab.com/handbook/engineering/incubation/" target="_blank">{{
      $options.i18n.learnMoreLabel
    }}</gl-link>
  </gl-alert>
</template>

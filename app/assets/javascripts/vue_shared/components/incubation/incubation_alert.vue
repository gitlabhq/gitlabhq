<script>
import { GlAlert, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'IncubationAlert',
  components: { GlAlert, GlLink },
  props: {
    featureName: {
      type: String,
      required: true,
    },
    linkToFeedbackIssue: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isAlertDismissed: false,
    };
  },
  computed: {
    shouldShowAlert() {
      return !this.isAlertDismissed;
    },
    titleLabel() {
      return sprintf(this.$options.i18n.titleLabel, { featureName: this.featureName });
    },
  },
  methods: {
    dismissAlert() {
      this.isAlertDismissed = true;
    },
  },
  i18n: {
    titleLabel: s__('Incubation|%{featureName} is in incubating phase'),
    contentLabel: s__(
      'Incubation|GitLab incubates features to explore new use cases. These features are updated regularly, and support is limited.',
    ),
    learnMoreLabel: s__('Incubation|Learn more about incubating features'),
    feedbackLabel: s__('Incubation|Give feedback on this feature'),
  },
};
</script>

<template>
  <gl-alert
    v-if="shouldShowAlert"
    :title="titleLabel"
    variant="warning"
    :primary-button-text="$options.i18n.feedbackLabel"
    :primary-button-link="linkToFeedbackIssue"
    @dismiss="dismissAlert"
  >
    {{ $options.i18n.contentLabel }}
    <gl-link href="https://about.gitlab.com/handbook/engineering/incubation/" target="_blank">{{
      $options.i18n.learnMoreLabel
    }}</gl-link>
  </gl-alert>
</template>

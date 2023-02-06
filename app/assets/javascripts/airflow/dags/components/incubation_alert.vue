<script>
import { GlAlert, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  name: 'AirflowIncubationAlert',
  components: { GlAlert, GlLink },
  data() {
    return {
      isAlertDismissed: false,
    };
  },
  computed: {
    hasAlert() {
      return !this.isAlertDismissed;
    },
  },
  methods: {
    dismissAlert() {
      this.isAlertDismissed = true;
    },
  },
  i18n: {
    titleLabel: s__('Airflow|GitLab Airflow integration is in the Incubating Phase.'),
    contentLabel: s__(
      'Incubation|GitLab incubates features to explore new use cases. These features are updated regularly, and support is limited.',
    ),
    learnMoreLabel: __('Learn more'),
    feedbackLabel: __('Feedback'),
  },
};
</script>

<template>
  <gl-alert
    v-if="hasAlert"
    :title="$options.i18n.titleLabel"
    variant="warning"
    :primary-button-text="$options.i18n.feedbackLabel"
    primary-button-link="https://gitlab.com/gitlab-org/incubation-engineering/airflow/meta/-/issues/2"
    @dismiss="dismissAlert"
  >
    {{ $options.i18n.contentLabel }}
    <gl-link
      href="https://about.gitlab.com/handbook/engineering/incubation/airflow/"
      target="_blank"
      >{{ $options.i18n.learnMoreLabel }}</gl-link
    >
  </gl-alert>
</template>

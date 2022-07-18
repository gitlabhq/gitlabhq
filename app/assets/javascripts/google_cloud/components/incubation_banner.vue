<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';

const FEATURE_REQUEST_KEY = 'feature_request';
const REPORT_BUG_KEY = 'report_bug';
const GENERAL_FEEDBACK_KEY = 'general_feedback';

export default {
  components: { GlAlert, GlLink, GlSprintf },
  methods: {
    feedbackUrl(template) {
      return `https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/feedback/-/issues/new?issuable_template=${template}`;
    },
  },
  FEATURE_REQUEST_KEY,
  REPORT_BUG_KEY,
  GENERAL_FEEDBACK_KEY,
};
</script>

<template>
  <gl-alert :dismissible="false" variant="info">
    {{ __('This is an experimental feature developed by GitLab Incubation Engineering.') }}
    <gl-sprintf
      :message="
        __(
          'We invite you to %{featureLinkStart}request a feature%{featureLinkEnd}, %{bugLinkStart}report a bug%{bugLinkEnd} or %{feedbackLinkStart}share feedback%{feedbackLinkEnd}',
        )
      "
    >
      <template #featureLink="{ content }">
        <gl-link :href="feedbackUrl($options.FEATURE_REQUEST_KEY)">{{ content }}</gl-link>
      </template>
      <template #bugLink="{ content }">
        <gl-link :href="feedbackUrl($options.REPORT_BUG_KEY)">{{ content }}</gl-link>
      </template>
      <template #feedbackLink="{ content }">
        <gl-link :href="feedbackUrl($options.GENERAL_FEEDBACK_KEY)">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>

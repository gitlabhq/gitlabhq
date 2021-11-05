<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  components: { GlAlert, GlLink, GlSprintf },
  props: {
    shareFeedbackUrl: {
      required: true,
      type: String,
    },
    reportBugUrl: {
      required: true,
      type: String,
    },
    featureRequestUrl: {
      required: true,
      type: String,
    },
  },
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
        <gl-link :href="featureRequestUrl">{{ content }}</gl-link>
      </template>
      <template #bugLink="{ content }">
        <gl-link :href="reportBugUrl">{{ content }}</gl-link>
      </template>
      <template #feedbackLink="{ content }">
        <gl-link :href="shareFeedbackUrl">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>

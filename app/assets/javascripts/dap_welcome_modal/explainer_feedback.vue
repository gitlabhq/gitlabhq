<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import Illustration from './illustrations/explainer_feedback_illustration.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    Illustration,
  },
  i18n: {
    feedbackMessage:
      '%{linkStart}Let us know what you think!%{linkEnd} This toggle is temporary while these changes are being refined. Soon, this sleek panel UI will be the default for everyone.',
  },
};
</script>

<template>
  <div class="slide">
    <p class="gl-mb-7">
      <gl-sprintf :message="$options.i18n.feedbackMessage">
        <template #link="{ content }">
          <gl-link
            href="https://gitlab.com/gitlab-org/gitlab/-/issues/577554"
            target="_blank"
            rel="noopener"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>

    <illustration />
  </div>
</template>

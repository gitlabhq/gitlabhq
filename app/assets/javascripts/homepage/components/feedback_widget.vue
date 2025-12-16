<script>
import { GlLink } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_FEEDBACK,
} from '../tracking_constants';

export default {
  components: {
    GlLink,
  },
  mixins: [InternalEvents.mixin()],
  methods: {
    handleExternalFeedbackClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_FEEDBACK,
        property: 'external_feedback_link',
      });
    },
  },
};
</script>

<template>
  <div class="gl-border gl-rounded-pill gl-p-5">
    <h2 class="gl-heading-4 gl-mb-4 gl-mt-0">
      {{ s__('HomePageFeedbackWidget|Share your feedback') }}
    </h2>

    <p class="gl-mb-4 gl-text-subtle">
      {{
        s__(
          'HomePageFeedbackWidget|Help us improve the new homepage by sharing your thoughts and suggestions.',
        )
      }}
    </p>

    <gl-link
      href="https://gitlab.com/gitlab-org/gitlab/-/issues/553938"
      target="_blank"
      data-testid="external-feedback-link"
      @click="handleExternalFeedbackClick"
    >
      {{ __('Leave feedback') }}
    </gl-link>
  </div>
</template>

<script>
import { GlBanner } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import {
  I18N_FEEDBACK_BANNER_TITLE,
  I18N_FEEDBACK_BANNER_BODY,
  I18N_FEEDBACK_BANNER_BUTTON,
  FEEDBACK_URL,
} from '../constants';

export default {
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  inject: ['artifactsManagementFeedbackImagePath'],
  FEEDBACK_URL,
  i18n: {
    title: I18N_FEEDBACK_BANNER_TITLE,
    body: I18N_FEEDBACK_BANNER_BODY,
    button: I18N_FEEDBACK_BANNER_BUTTON,
  },
};
</script>
<template>
  <user-callout-dismisser feature-name="artifacts_management_page_feedback_banner">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        class="gl-mb-6"
        :title="$options.i18n.title"
        :button-text="$options.i18n.button"
        :button-link="$options.FEEDBACK_URL"
        :svg-path="artifactsManagementFeedbackImagePath"
        @close="dismiss"
      >
        <p>{{ $options.i18n.body }}</p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>

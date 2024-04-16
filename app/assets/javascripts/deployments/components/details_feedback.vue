<script>
import { GlAlert } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
    UserCalloutDismisser,
  },
  i18n: {
    header: s__('Deployment|What would you like to see here?'),
    body: s__(
      "Deployment|We know this page is a bit empty at the moment, but we're working hard to bring you a great experience! In the meantime, we'd love to hear your feedback.",
    ),
    action: s__('Deployment|Leave feedback'),
  },
  FEEDBACK_ISSUE_LINK: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450700',
};
</script>
<template>
  <user-callout-dismisser feature-name="deployment_details_feedback">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-alert
        v-if="shouldShowCallout"
        :title="$options.i18n.header"
        :primary-button-text="$options.i18n.action"
        :primary-button-link="$options.FEEDBACK_ISSUE_LINK"
        @dismiss="dismiss"
      >
        {{ $options.i18n.body }}
      </gl-alert>
    </template>
  </user-callout-dismisser>
</template>

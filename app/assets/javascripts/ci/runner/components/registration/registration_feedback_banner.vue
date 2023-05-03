<script>
import ILLUSTRATION_URL from '@gitlab/svgs/dist/illustrations/multi-editor_all_changes_committed_empty.svg?url';
import { GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

const FEEDBACK_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/387993';

export default {
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  i18n: {
    title: s__("Runners|We've made some changes and want your feedback"),
    body: s__(
      "Runners|We've been making improvements to how you register runners so that it's more secure and efficient. Tell us how we're doing.",
    ),
    button: s__('Runners|Add your feedback to this issue'),
  },
  ILLUSTRATION_URL,
  FEEDBACK_ISSUE_URL,
};
</script>
<template>
  <user-callout-dismisser feature-name="create_runner_workflow_banner">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        class="gl-my-6"
        :title="$options.i18n.title"
        :svg-path="$options.ILLUSTRATION_URL"
        :button-text="$options.i18n.button"
        :button-link="$options.FEEDBACK_ISSUE_URL"
        @close="dismiss"
      >
        <p>{{ $options.i18n.body }}</p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>

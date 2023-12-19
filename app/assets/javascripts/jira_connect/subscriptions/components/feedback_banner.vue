<script>
import { GlBanner } from '@gitlab/ui';
import ChatBubbleSvg from '@gitlab/svgs/dist/illustrations/chat-sm.svg?url';
import { s__, __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    GlBanner,
    LocalStorageSync,
  },

  data() {
    return {
      feedbackBannerDismissed: false,
    };
  },

  methods: {
    handleBannerClose() {
      this.feedbackBannerDismissed = true;
    },
  },

  i18n: {
    title: s__('JiraConnect|Tell us what you think!'),
    body: s__(
      'JiraConnect|We would love to learn more about your experience with the GitLab for Jira Cloud App.',
    ),
    dismissLabel: __('Dismiss'),
    buttonText: __('Give feedback'),
  },
  feedbackBannerKey: 'jira_connect_feedback_banner',
  feedbackIssueUrl: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413652',
  buttonAttributes: {
    target: '_blank',
  },
  ChatBubbleSvg,
};
</script>

<template>
  <local-storage-sync v-model="feedbackBannerDismissed" :storage-key="$options.feedbackBannerKey">
    <gl-banner
      v-if="!feedbackBannerDismissed"
      :title="$options.i18n.title"
      :button-attributes="$options.buttonAttributes"
      :button-text="$options.i18n.buttonText"
      :button-link="$options.feedbackIssueUrl"
      :dismiss-label="$options.i18n.dismissLabel"
      :svg-path="$options.ChatBubbleSvg"
      @close="handleBannerClose"
    >
      <p>{{ $options.i18n.body }}</p>
    </gl-banner>
  </local-storage-sync>
</template>

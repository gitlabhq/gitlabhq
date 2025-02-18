<script>
import { GlAlert, GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'WebIdeError',
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
    GlLink,
  },
  props: {
    signOutPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    reload: () => window.location.reload(),
  },
  i18n: {
    title: __('Failed to load the Web IDE'),
    message: __(
      'For more information, see the developer console. Try to reload the page or sign out and in again. If the issue persists, %{reportIssueStart}report a problem%{reportIssueEnd}.',
    ),
    primaryButtonText: __('Reload'),
    secondaryButtonText: __('Sign out'),
  },
  REPORT_ISSUE_URL: helpPagePath('user/project/web_ide/_index', { anchor: '#report-a-problem' }),
};
</script>
<template>
  <div class="m-auto gl-max-w-80 gl-pt-6">
    <gl-alert variant="danger" :dismissible="false" :title="$options.i18n.title">
      <gl-sprintf :message="$options.i18n.message">
        <template #reportIssue="{ content }">
          <gl-link :href="$options.REPORT_ISSUE_URL" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <template #actions>
        <gl-button variant="confirm" category="primary" @click="reload">{{
          $options.i18n.primaryButtonText
        }}</gl-button>
        <gl-button category="secondary" class="gl-ml-3" data-method="post" :href="signOutPath">
          {{ $options.i18n.secondaryButtonText }}
        </gl-button>
      </template>
    </gl-alert>
  </div>
</template>

<script>
import { GlAvatar, GlButton, GlLink } from '@gitlab/ui';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import { REPORT_HEADER_I18N } from '../constants';

export default {
  name: 'ReportHeader',
  components: {
    GlAvatar,
    GlButton,
    GlLink,
    AbuseReportActions,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    actions: {
      type: Object,
      required: true,
    },
  },
  i18n: REPORT_HEADER_I18N,
};
</script>

<template>
  <header
    class="gl-py-4 gl-border-b gl-display-flex gl-justify-content-space-between gl-xs-flex-direction-column"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-avatar :size="48" :src="user.avatarUrl" />
      <h1 class="gl-font-size-h-display gl-my-0 gl-ml-3">
        {{ user.name }}
      </h1>
      <gl-link :href="user.path" class="gl-ml-3"> @{{ user.username }} </gl-link>
    </div>
    <nav class="gl-display-flex gl-sm-align-items-center gl-mt-4 gl-sm-mt-0">
      <gl-button :href="user.adminPath" class="flex-grow-1">
        {{ $options.i18n.adminProfile }}
      </gl-button>
      <abuse-report-actions :report="actions" class="gl-sm-ml-3" />
    </nav>
  </header>
</template>

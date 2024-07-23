<script>
import { GlBadge, GlAvatar, GlButton, GlLink } from '@gitlab/ui';
import { REPORT_HEADER_I18N, STATUS_OPEN, STATUS_CLOSED } from '../constants';
import ReportActions from './report_actions.vue';

export default {
  name: 'ReportHeader',
  components: {
    GlBadge,
    GlAvatar,
    GlButton,
    GlLink,
    ReportActions,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    report: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: this.report.status,
    };
  },
  computed: {
    isOpen() {
      return this.state === STATUS_OPEN;
    },
    badgeVariant() {
      return this.isOpen ? 'success' : 'info';
    },
    badgeText() {
      return REPORT_HEADER_I18N[this.state];
    },
    badgeIcon() {
      return this.isOpen ? 'issues' : 'issue-closed';
    },
  },
  methods: {
    closeReport() {
      this.state = STATUS_CLOSED;
    },
  },
  i18n: REPORT_HEADER_I18N,
};
</script>

<template>
  <header class="gl-border-b gl-flex gl-flex-col gl-justify-between gl-py-4 sm:gl-flex-row">
    <div class="gl-flex gl-items-center gl-gap-3">
      <gl-badge :variant="badgeVariant" :icon="badgeIcon" :aria-label="badgeText">
        {{ badgeText }}
      </gl-badge>
      <gl-avatar :size="48" :src="user.avatarUrl" />
      <h1 class="gl-my-0 gl-text-size-h-display">
        {{ user.name }}
      </h1>
      <gl-link :href="user.path"> @{{ user.username }} </gl-link>
    </div>
    <nav class="gl-mt-4 gl-flex gl-flex-col sm:gl-mt-0 sm:gl-flex-row sm:gl-items-center">
      <gl-button :href="user.adminPath">
        {{ $options.i18n.adminProfile }}
      </gl-button>
      <report-actions
        :user="user"
        :report="report"
        class="gl-mt-3 sm:gl-ml-3 sm:gl-mt-0"
        @closeReport="closeReport"
        v-on="$listeners"
      />
    </nav>
  </header>
</template>

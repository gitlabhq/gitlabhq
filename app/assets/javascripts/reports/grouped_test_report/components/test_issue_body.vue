<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { sprintf, n__ } from '~/locale';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { STATUS_NEUTRAL } from '../../constants';

export default {
  name: 'TestIssueBody',
  components: {
    GlBadge,
    GlButton,
    IssueStatusIcon,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    recentFailureMessage() {
      return sprintf(
        n__(
          'Reports|Failed %{count} time in %{base_branch} in the last 14 days',
          'Reports|Failed %{count} times in %{base_branch} in the last 14 days',
          this.issue.recent_failures?.count,
        ),
        this.issue.recent_failures,
      );
    },
    showRecentFailures() {
      return this.issue.recent_failures?.count && this.issue.recent_failures?.base_branch;
    },
    status() {
      return this.issue.status || STATUS_NEUTRAL;
    },
  },
  methods: {
    ...mapActions(['openModal']),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-mt-2 gl-mb-2">
    <issue-status-icon :status="status" :status-icon-size="24" class="gl-mr-3" />
    <gl-button
      button-text-classes="gl-white-space-normal! gl-word-break-all gl-text-left"
      variant="link"
      data-testid="test-issue-body-description"
      @click="openModal({ issue })"
    >
      <gl-badge
        v-if="showRecentFailures"
        variant="warning"
        class="gl-mr-2"
        data-testid="test-issue-body-recent-failures"
      >
        {{ recentFailureMessage }}
      </gl-badge>
      {{ issue.name }}
    </gl-button>
  </div>
</template>

<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlBadge,
    GlTab,
    GlTabs,
  },
  inject: {
    jobCounts: {
      default: {},
    },
    jobStatuses: {
      default: {},
    },
  },
  computed: {
    tabs() {
      return [
        {
          text: __('All'),
          count: this.jobCounts.all,
          scope: null,
          testId: 'jobs-all-tab',
        },
        {
          text: __('Pending'),
          count: this.jobCounts.pending,
          scope: this.jobStatuses.pending,
          testId: 'jobs-pending-tab',
        },
        {
          text: __('Running'),
          count: this.jobCounts.running,
          scope: this.jobStatuses.running,
          testId: 'jobs-running-tab',
        },
        {
          text: __('Finished'),
          count: this.jobCounts.finished,
          scope: [this.jobStatuses.success, this.jobStatuses.failed, this.jobStatuses.canceled],
          testId: 'jobs-finished-tab',
        },
      ];
    },
  },
};
</script>

<template>
  <gl-tabs content-class="gl-pb-0">
    <gl-tab
      v-for="tab in tabs"
      :key="tab.text"
      :title-link-attributes="{ 'data-testid': tab.testId }"
      @click="$emit('fetchJobsByStatus', tab.scope)"
    >
      <template #title>
        <span>{{ tab.text }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>

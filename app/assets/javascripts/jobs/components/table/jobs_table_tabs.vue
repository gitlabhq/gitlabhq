<script>
import { GlBadge, GlTab, GlTabs, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    GlLoadingIcon,
  },
  inject: {
    jobStatuses: {
      default: {},
    },
  },
  props: {
    allJobsCount: {
      type: Number,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tabs() {
      return [
        {
          text: s__('Jobs|All'),
          count: this.allJobsCount,
          scope: null,
          testId: 'jobs-all-tab',
          showBadge: true,
        },
        {
          text: s__('Jobs|Finished'),
          scope: [this.jobStatuses.success, this.jobStatuses.failed, this.jobStatuses.canceled],
          testId: 'jobs-finished-tab',
          showBadge: false,
        },
      ];
    },
    showLoadingIcon() {
      return this.loading && !this.allJobsCount;
    },
  },
};
</script>

<template>
  <gl-tabs content-class="gl-py-0">
    <gl-tab
      v-for="tab in tabs"
      :key="tab.text"
      :title-link-attributes="{ 'data-testid': tab.testId }"
      @click="$emit('fetchJobsByStatus', tab.scope)"
    >
      <template #title>
        <span>{{ tab.text }}</span>
        <gl-loading-icon v-if="showLoadingIcon && tab.showBadge" class="gl-ml-2" />

        <gl-badge v-else-if="tab.showBadge" size="sm" class="gl-tab-counter-badge">
          {{ tab.count }}
        </gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>

<script>
import { GlBadge, GlTab, GlTabs, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { limitedCounterWithDelimiter } from '~/lib/utils/text_utility';

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
          count: limitedCounterWithDelimiter(this.allJobsCount),
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
      :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        'data-testid': tab.testId,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
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

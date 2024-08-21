<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    statuses() {
      return [
        {
          class: 'ci-status-icon-canceled',
          icon: 'status_canceled',
          text: s__('Pipeline|Canceled'),
          value: 'canceled',
        },
        {
          class: 'ci-status-icon-created',
          icon: 'status_created',
          text: s__('Pipeline|Created'),
          value: 'created',
        },
        {
          class: 'ci-status-icon-failed',
          icon: 'status_failed',
          text: s__('Pipeline|Failed'),
          value: 'failed',
        },
        {
          class: 'ci-status-icon-manual',
          icon: 'status_manual',
          text: s__('Pipeline|Manual'),
          value: 'manual',
        },
        {
          class: 'ci-status-icon-success',
          icon: 'status_success',
          text: s__('Pipeline|Passed'),
          value: 'success',
        },
        {
          class: 'ci-status-icon-pending',
          icon: 'status_pending',
          text: s__('Pipeline|Pending'),
          value: 'pending',
        },
        {
          class: 'ci-status-icon-running',
          icon: 'status_running',
          text: s__('Pipeline|Running'),
          value: 'running',
        },
        {
          class: 'ci-status-icon-skipped',
          icon: 'status_skipped',
          text: s__('Pipeline|Skipped'),
          value: 'skipped',
        },
      ];
    },
    findActiveStatus() {
      return this.statuses.find((status) => status.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <div :class="findActiveStatus.class">
          <gl-icon :name="findActiveStatus.icon" class="gl-mr-2 gl-block" />
        </div>
        <span>{{ findActiveStatus.text }}</span>
      </div>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="(status, index) in statuses"
        :key="index"
        :value="status.value"
      >
        <div class="gl-flex" :class="status.class">
          <gl-icon :name="status.icon" class="gl-mr-3" />
          <span>{{ status.text }}</span>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>

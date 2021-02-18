<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { roundDownFloat } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    successLabel: {
      type: String,
      required: false,
      default: 'successful',
    },
    failureLabel: {
      type: String,
      required: false,
      default: 'failed',
    },
    neutralLabel: {
      type: String,
      required: false,
      default: 'neutral',
    },
    unavailableLabel: {
      type: String,
      required: false,
      default: __('Not available'),
    },
    successCount: {
      type: Number,
      required: true,
    },
    failureCount: {
      type: Number,
      required: true,
    },
    totalCount: {
      type: Number,
      required: true,
    },
    hideTooltips: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    neutralCount() {
      return this.totalCount - this.successCount - this.failureCount;
    },
    successPercent() {
      return this.getPercent(this.successCount);
    },
    successBarStyle() {
      return this.barStyle(this.successPercent);
    },
    successTooltip() {
      return this.getTooltip(this.successLabel, this.successCount);
    },
    failurePercent() {
      return this.getPercent(this.failureCount);
    },
    failureBarStyle() {
      return this.barStyle(this.failurePercent);
    },
    failureTooltip() {
      return this.getTooltip(this.failureLabel, this.failureCount);
    },
    neutralPercent() {
      return this.getPercent(this.neutralCount);
    },
    neutralBarStyle() {
      return this.barStyle(this.neutralPercent);
    },
    neutralTooltip() {
      return this.getTooltip(this.neutralLabel, this.neutralCount);
    },
  },
  methods: {
    getPercent(count) {
      if (!this.totalCount) {
        return 0;
      }

      const percent = roundDownFloat((count / this.totalCount) * 100, 1);
      if (percent > 0 && percent < 1) {
        return '< 1';
      }
      return percent;
    },
    barStyle(percent) {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `width: ${percent}%;`;
    },
    getTooltip(label, count) {
      return this.hideTooltips ? '' : `${label}: ${count}`;
    },
  },
};
</script>

<template>
  <div :class="cssClass" class="stacked-progress-bar">
    <span v-if="!totalCount" class="status-unavailable">{{ unavailableLabel }}</span>
    <span
      v-if="successPercent"
      v-gl-tooltip
      :title="successTooltip"
      :style="successBarStyle"
      class="status-green"
      data-placement="bottom"
    >
      {{ successPercent }}%
    </span>
    <span
      v-if="neutralPercent"
      v-gl-tooltip
      :title="neutralTooltip"
      :style="neutralBarStyle"
      class="status-neutral"
      data-placement="bottom"
    >
      {{ neutralPercent }}%
    </span>
    <span
      v-if="failurePercent"
      v-gl-tooltip
      :title="failureTooltip"
      :style="failureBarStyle"
      class="status-red"
      data-placement="bottom"
    >
      {{ failurePercent }}%
    </span>
  </div>
</template>

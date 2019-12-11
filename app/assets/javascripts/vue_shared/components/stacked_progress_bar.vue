<script>
import { roundOffFloat } from '~/lib/utils/common_utils';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  props: {
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
    successLabel: {
      type: String,
      required: true,
    },
    failureLabel: {
      type: String,
      required: true,
    },
    neutralLabel: {
      type: String,
      required: true,
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

      const percent = roundOffFloat((count / this.totalCount) * 100, 1);
      if (percent > 0 && percent < 1) {
        return '< 1';
      }
      return percent;
    },
    barStyle(percent) {
      // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `width: ${percent}%;`;
    },
    getTooltip(label, count) {
      return `${label}: ${count}`;
    },
  },
};
</script>

<template>
  <div :class="cssClass" class="stacked-progress-bar">
    <span v-if="!totalCount" class="status-unavailable"> {{ __('Not available') }} </span>
    <span
      v-if="successPercent"
      v-tooltip
      :title="successTooltip"
      :style="successBarStyle"
      class="status-green"
      data-placement="bottom"
    >
      {{ successPercent }}%
    </span>
    <span
      v-if="neutralPercent"
      v-tooltip
      :title="neutralTooltip"
      :style="neutralBarStyle"
      class="status-neutral"
      data-placement="bottom"
    >
      {{ neutralPercent }}%
    </span>
    <span
      v-if="failurePercent"
      v-tooltip
      :title="failureTooltip"
      :style="failureBarStyle"
      class="status-red"
      data-placement="bottom"
    >
      {{ failurePercent }}%
    </span>
  </div>
</template>

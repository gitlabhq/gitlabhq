<script>
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
      return Math.ceil((count / this.totalCount) * 100);
    },
    barStyle(percent) {
      return `width: ${percent}%;`;
    },
    getTooltip(label, count) {
      return `${label}: ${count}`;
    },
  },
};
</script>

<template>
  <div
    class="stacked-progress-bar"
    :class="cssClass"
  >
    <span
      v-if="!totalCount"
      class="status-unavailable"
    >
      {{ __("Not available") }}
    </span>
    <span
      v-tooltip
      v-if="successPercent"
      class="status-green"
      data-placement="bottom"
      :title="successTooltip"
      :style="successBarStyle"
    >
      {{ successPercent }}%
    </span>
    <span
      v-tooltip
      v-if="neutralPercent"
      class="status-neutral"
      data-placement="bottom"
      :title="neutralTooltip"
      :style="neutralBarStyle"
    >
      {{ neutralPercent }}%
    </span>
    <span
      v-tooltip
      v-if="failurePercent"
      class="status-red"
      data-placement="bottom"
      :title="failureTooltip"
      :style="failureBarStyle"
    >
      {{ failurePercent }}%
    </span>
  </div>
</template>

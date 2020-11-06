<script>
import {
  GlCard,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlLink,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';

export default {
  name: 'MetricCard',
  components: {
    GlCard,
    GlSkeletonLoading,
    GlLink,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    metrics: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    valueText(metric) {
      const { value = null, unit = null } = metric;
      if (!value || value === '-') return '-';
      return unit && value ? `${value} ${unit}` : value;
    },
  },
};
</script>
<template>
  <gl-card class="gl-mb-5">
    <template #header>
      <strong ref="title">{{ title }}</strong>
    </template>
    <template #default>
      <gl-skeleton-loading v-if="isLoading" class="gl-h-auto gl-py-3" />
      <div v-else ref="metricsWrapper" class="gl-display-flex">
        <div
          v-for="metric in metrics"
          :key="metric.key"
          ref="metricItem"
          class="js-metric-card-item gl-flex-grow-1 gl-text-center"
        >
          <gl-link v-if="metric.link" :href="metric.link">
            <h3 class="gl-my-2 gl-text-blue-700">{{ valueText(metric) }}</h3>
          </gl-link>
          <h3 v-else class="gl-my-2">{{ valueText(metric) }}</h3>
          <p class="text-secondary gl-font-sm gl-mb-2">
            {{ metric.label }}
            <span v-if="metric.tooltipText">
              &nbsp;
              <gl-icon
                v-gl-tooltip="{ title: metric.tooltipText }"
                :size="14"
                class="gl-vertical-align-middle"
                name="question"
                data-testid="tooltip"
              />
            </span>
          </p>
        </div>
      </div>
    </template>
  </gl-card>
</template>

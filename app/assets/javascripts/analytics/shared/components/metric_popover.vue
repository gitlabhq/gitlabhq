<script>
import { GlPopover, GlLink, GlIcon } from '@gitlab/ui';

export default {
  name: 'MetricPopover',
  components: {
    GlPopover,
    GlLink,
    GlIcon,
  },
  props: {
    metric: {
      type: Object,
      required: true,
      validator: (metric) => ['label', 'description'].every((key) => metric[key]),
    },
    metricUrl: {
      type: String,
      required: false,
      default: '',
    },
    target: {
      type: String,
      required: true,
    },
  },
  computed: {
    docsLink() {
      return this.metric.docsLink;
    },
  },
};
</script>

<template>
  <gl-popover :target="target" placement="top">
    <template #title>
      <div class="gl-flex gl-w-full gl-items-center gl-justify-between gl-py-1">
        <span data-testid="metric-label">{{ metric.label }}</span>
        <gl-link
          v-if="metricUrl"
          :href="metricUrl"
          class="gl-text-sm gl-font-normal"
          data-testid="metric-link"
          >{{ s__('ValueStreamAnalytics|View details') }}
          <gl-icon name="chart" />
        </gl-link>
      </div>
    </template>
    <p data-testid="metric-description" class="gl-mb-0">{{ metric.description }}</p>
    <gl-link
      v-if="docsLink"
      :href="docsLink"
      class="gl-mt-2 gl-block gl-text-sm"
      target="_blank"
      data-testid="metric-docs-link"
      >{{ __('Learn more') }}
      <gl-icon name="external-link" class="gl-align-middle" />
    </gl-link>
  </gl-popover>
</template>

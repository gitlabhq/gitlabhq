<script>
import { GlPopover, GlLink, GlIcon } from '@gitlab/ui';
import { METRIC_POPOVER_LABEL } from '../constants';

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
    },
    target: {
      type: String,
      required: true,
    },
  },
  computed: {
    metricLink() {
      return this.metric.links?.find((link) => !link.docs_link);
    },
    docsLink() {
      return this.metric.links?.find((link) => link.docs_link);
    },
  },
  metricPopoverLabel: METRIC_POPOVER_LABEL,
};
</script>

<template>
  <gl-popover :target="target" placement="top">
    <template #title>
      <div
        class="gl-display-flex gl-justify-content-space-between gl-text-right gl-py-1 gl-align-items-center"
      >
        <span data-testid="metric-label">{{ metric.label }}</span>
        <gl-link
          v-if="metricLink"
          :href="metricLink.url"
          class="gl-font-sm gl-font-weight-normal"
          data-testid="metric-link"
          >{{ $options.metricPopoverLabel }}
          <gl-icon name="chart" />
        </gl-link>
      </div>
    </template>
    <span v-if="metric.description" data-testid="metric-description">{{ metric.description }}</span>
    <gl-link
      v-if="docsLink"
      :href="docsLink.url"
      class="gl-font-sm"
      target="_blank"
      data-testid="metric-docs-link"
      >{{ docsLink.label }}
      <gl-icon name="external-link" class="gl-vertical-align-middle" />
    </gl-link>
  </gl-popover>
</template>

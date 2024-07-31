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
      <div class="gl-flex gl-items-center gl-justify-between gl-py-1 gl-text-right">
        <span data-testid="metric-label">{{ metric.label }}</span>
        <gl-link
          v-if="metricLink"
          :href="metricLink.url"
          class="gl-text-sm gl-font-normal"
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
      class="gl-text-sm"
      target="_blank"
      data-testid="metric-docs-link"
      >{{ docsLink.label }}
      <gl-icon name="external-link" class="gl-align-middle" />
    </gl-link>
  </gl-popover>
</template>

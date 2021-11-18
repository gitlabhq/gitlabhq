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
    },
    target: {
      type: String,
      required: true,
    },
  },
  computed: {
    metricLinks() {
      return this.metric.links?.filter((link) => !link.docs_link) || [];
    },
    docsLink() {
      return this.metric.links?.find((link) => link.docs_link);
    },
  },
};
</script>

<template>
  <gl-popover :target="target" placement="bottom">
    <template #title>
      <span class="gl-display-block gl-text-left" data-testid="metric-label">{{
        metric.label
      }}</span>
    </template>
    <div
      v-for="(link, idx) in metricLinks"
      :key="`link-${idx}`"
      class="gl-display-flex gl-justify-content-space-between gl-text-right gl-py-1"
      data-testid="metric-link"
    >
      <span>{{ link.label }}</span>
      <gl-link :href="link.url" class="gl-font-sm">
        {{ link.name }}
      </gl-link>
    </div>
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

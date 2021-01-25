<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    monitoringUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return __('Monitoring');
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
    class="monitoring-url gl-display-none gl-sm-display-none gl-md-display-block"
    icon="chart"
    rel="noopener noreferrer nofollow"
    variant="default"
  />
</template>

<script>
import { GlDeprecatedButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
export default {
  components: {
    GlIcon,
    GlDeprecatedButton,
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
  <gl-deprecated-button
    v-gl-tooltip
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
    class="monitoring-url d-none d-sm-none d-md-block"
    rel="noopener noreferrer nofollow"
    variant="default"
  >
    <gl-icon name="chart" />
  </gl-deprecated-button>
</template>

<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
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
    class="monitoring-url d-none d-sm-none d-md-block"
    rel="noopener noreferrer nofollow"
    variant="default"
  >
    <icon name="chart" />
  </gl-button>
</template>

<script>
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  props: {
    monitoringUrl: {
      type: String,
      required: true,
    },
  },

  directives: {
    tooltip,
  },

  computed: {
    title() {
      return 'Monitoring';
    },
  },
};
</script>
<template>
  <a
    v-tooltip
    class="btn monitoring-url hidden-xs hidden-sm"
    data-container="body"
    rel="noopener noreferrer nofollow"
    :href="monitoringUrl"
    :title="title"
    :aria-label="title">
    <i
      class="fa fa-area-chart"
      aria-hidden="true"
      />
  </a>
</template>

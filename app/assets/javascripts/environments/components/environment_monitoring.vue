<script>
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
export default {
  props: {
    monitoringUrl: {
      type: String,
      required: true,
    },
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
    class="btn monitoring-url has-tooltip"
    data-container="body"
    target="_blank"
    rel="noopener noreferrer nofollow"
    :href="monitoringUrl"
    :title="title"
    :aria-label="title">
    <i
      class="fa fa-area-chart"
      aria-hidden="true" />
  </a>
</template>

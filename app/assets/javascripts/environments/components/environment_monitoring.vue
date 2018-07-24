<script>
/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
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
    v-tooltip
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
    class="btn monitoring-url d-none d-sm-none d-md-block"
    data-container="body"
    rel="noopener noreferrer nofollow"
  >
    <icon name="chart" />
  </a>
</template>

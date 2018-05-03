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
    class="btn monitoring-url hidden-xs hidden-sm"
    data-container="body"
    rel="noopener noreferrer nofollow"
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
  >
    <icon
      name="chart"
      :size="12"
    />
  </a>
</template>

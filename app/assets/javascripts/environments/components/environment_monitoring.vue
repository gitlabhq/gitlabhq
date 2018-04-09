<script>
  /**
  * Renders the Monitoring (Metrics) link in environments table.
  */
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
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
    class="btn monitoring-url d-none d-sm-none d-md-block"
    data-container="body"
    rel="noopener noreferrer nofollow"
    :href="monitoringUrl"
    :title="title"
    :aria-label="title"
  >
    <i
      class="fa fa-area-chart"
      aria-hidden="true"
    >
    </i>
  </a>
</template>

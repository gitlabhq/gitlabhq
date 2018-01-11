<script>
  /**
<<<<<<< HEAD
   * Renders the Monitoring (Metrics) link in environments table.
   */
=======
  * Renders the Monitoring (Metrics) link in environments table.
  */
>>>>>>> upstream/master
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
<<<<<<< HEAD
    },
    props: {
      monitoringUrl: {
        type: String,
        required: true,
      },
    },
=======
    },

    props: {
      monitoringUrl: {
        type: String,
        required: true,
      },
    },
>>>>>>> upstream/master

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
    <i
      class="fa fa-area-chart"
      aria-hidden="true"
    >
    </i>
  </a>
</template>

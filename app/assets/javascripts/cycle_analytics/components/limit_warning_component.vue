<script>
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    props: {
      count: {
        type: Number,
        required: true,
      },
    },
    directives: {
      tooltip,
    },
  };
</script>
<template>
  <span v-if="count === 50" class="events-info pull-right">
    <i
      class="fa fa-warning"
      v-tooltip
      aria-hidden="true"
      :title="n__('Limited to showing %d event at most', 'Limited to showing %d events at most', 50)"
      data-placement="top"></i>
    {{ n__('Showing %d event', 'Showing %d events', 50) }}
  </span>
</template>

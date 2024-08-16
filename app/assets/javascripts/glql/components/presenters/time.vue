<script>
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'TimePresenter',
  components: {
    TimeAgo,
  },
  props: {
    data: {
      required: true,
      type: String,
    },
  },
};
</script>
<template>
  <time-ago :time="data" />
</template>

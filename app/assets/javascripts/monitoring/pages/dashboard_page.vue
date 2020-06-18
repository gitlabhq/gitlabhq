<script>
import Dashboard from '../components/dashboard.vue';

export default {
  components: {
    Dashboard,
  },
  props: {
    dashboardProps: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <dashboard v-bind="{ ...dashboardProps }" />
</template>

<script>
import { mapActions } from 'vuex';
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
  created() {
    // This is to support the older URL <project>/-/environments/:env_id/metrics?dashboard=:path
    // and the new format <project>/-/metrics/:dashboardPath
    const encodedDashboard = this.$route.query.dashboard || this.$route.params.dashboard;
    const currentDashboard = encodedDashboard ? decodeURIComponent(encodedDashboard) : null;
    this.setCurrentDashboard({ currentDashboard });
  },
  methods: {
    ...mapActions('monitoringDashboard', ['setCurrentDashboard']),
  },
};
</script>
<template>
  <dashboard v-bind="{ ...dashboardProps }" />
</template>

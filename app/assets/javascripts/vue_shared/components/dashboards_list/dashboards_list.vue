<script>
import DashboardCard from './dashboard_card.vue';

export default {
  name: 'DashboardsList',
  components: {
    DashboardCard,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <!-- auto-fill keeps cards at a readable width regardless of how few
       dashboards exist; no grid-cols utility expresses that. -->
  <!-- eslint-disable tailwindcss/no-arbitrary-value -->
  <ul
    class="gl-m-0 gl-grid gl-list-none gl-grid-cols-[repeat(auto-fill,minmax(16rem,1fr))] gl-gap-5 gl-p-0"
    data-testid="dashboards-list"
  >
    <!-- eslint-enable tailwindcss/no-arbitrary-value -->
    <dashboard-card v-for="dashboard in dashboards" :key="dashboard.id" :dashboard="dashboard" />
  </ul>
</template>

<script>
import DashboardCard from './dashboard_card.vue';
import DashboardsTable from './dashboards_table.vue';

export default {
  name: 'DashboardsList',
  components: {
    DashboardCard,
    DashboardsTable,
  },
  props: {
    dashboards: {
      type: Array,
      required: true,
    },
    layout: {
      type: String,
      required: false,
      default: 'list',
      validator: (layout) => ['list', 'grid'].includes(layout),
    },
  },
};
</script>
<template>
  <dashboards-table v-if="layout === 'list'" :dashboards="dashboards" />
  <!-- auto-fill keeps cards at a readable width regardless of how few
       dashboards exist; no grid-cols utility expresses that. -->
  <!-- eslint-disable tailwindcss/no-arbitrary-value -->
  <ul
    v-else
    class="gl-m-0 gl-grid gl-list-none gl-grid-cols-[repeat(auto-fill,minmax(16rem,1fr))] gl-gap-5 gl-p-0"
    data-testid="dashboards-list"
  >
    <!-- eslint-enable tailwindcss/no-arbitrary-value -->
    <dashboard-card v-for="dashboard in dashboards" :key="dashboard.id" :dashboard="dashboard" />
  </ul>
</template>

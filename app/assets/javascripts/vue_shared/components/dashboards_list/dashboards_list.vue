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
  <div class="gl-@container">
    <ul
      class="gl-m-0 gl-grid gl-list-none gl-grid-cols-1 gl-gap-5 gl-p-0 @md:gl-grid-cols-2 @lg:gl-grid-cols-3"
      data-testid="dashboards-list"
    >
      <dashboard-card v-for="dashboard in dashboards" :key="dashboard.id" :dashboard="dashboard" />
    </ul>
  </div>
</template>

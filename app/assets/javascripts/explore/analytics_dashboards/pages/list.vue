<script>
import IndexLayout from '~/vue_shared/components/index_layout.vue';

// The route's controller is EE-only, so this CE page exists only to satisfy
// the `ee_else_ce` import in FOSS builds and is never reachable.
export default {
  name: 'ExploreAnalyticsDashboardsList',
  components: {
    IndexLayout,
  },
};
</script>
<template>
  <index-layout :heading="__('Analytics dashboards')" />
</template>

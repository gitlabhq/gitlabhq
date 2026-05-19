<script>
export default {
  name: 'ExploreAnalyticsDashboards',
  inject: {
    currentUserId: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <router-view :current-user-id="currentUserId" />
</template>

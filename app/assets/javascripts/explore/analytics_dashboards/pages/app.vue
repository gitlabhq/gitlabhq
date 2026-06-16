<script>
export default {
  name: 'ExploreAnalyticsDashboards',
  props: {
    currentUserId: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <router-view :current-user-id="currentUserId" />
</template>

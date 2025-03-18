<script>
import PlaceholderUsersStats from './placeholder_users_stats.vue';

export default {
  name: 'ImportUsageApp',
  components: {
    PlaceholderUsersStats,
  },
};
</script>

<template>
  <div>
    <h2 class="gl-heading-2 gl-my-3">{{ __('Import') }}</h2>

    <placeholder-users-stats />
  </div>
</template>

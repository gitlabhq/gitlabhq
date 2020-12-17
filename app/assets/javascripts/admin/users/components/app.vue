<script>
import UsersTable from './users_table.vue';

export default {
  components: {
    UsersTable,
  },
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    paths: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <users-table :users="users" :paths="paths" />
  </div>
</template>

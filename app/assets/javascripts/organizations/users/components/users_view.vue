<script>
import { GlLoadingIcon } from '@gitlab/ui';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';

export default {
  name: 'UsersView',
  components: {
    GlLoadingIcon,
    UsersTable,
  },
  inject: ['paths'],
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
  <users-table v-else :users="users" :admin-user-path="paths.adminUser" />
</template>

<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';

export default {
  name: 'UsersView',
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    UsersTable,
  },
  inject: ['paths'],
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    pageInfo: {
      type: Object,
      required: true,
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
  <div>
    <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
    <template v-else>
      <users-table :users="users" :admin-user-path="paths.adminUser" />
      <div class="gl-display-flex gl-justify-content-center">
        <gl-keyset-pagination
          v-bind="pageInfo"
          :prev-text="__('Previous')"
          :next-text="__('Next')"
          @prev="$emit('prev')"
          @next="$emit('next')"
        />
      </div>
    </template>
  </div>
</template>

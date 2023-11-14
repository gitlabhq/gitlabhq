<script>
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import getUsersGroupCountsQuery from '../graphql/queries/get_users_group_counts.query.graphql';
import UserActions from './user_actions.vue';

export default {
  components: {
    UsersTable,
    UserActions,
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
  data() {
    return {
      groupCounts: {},
    };
  },
  apollo: {
    groupCounts: {
      query: getUsersGroupCountsQuery,
      variables() {
        return {
          usernames: this.users.map((user) => user.username),
        };
      },
      update(data) {
        const nodes = data?.users?.nodes || [];
        const parsedIds = convertNodeIdsFromGraphQLIds(nodes);

        return parsedIds.reduce((acc, { id, groupCount }) => {
          acc[id] = groupCount || 0;
          return acc;
        }, {});
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.groupCountFetchError,
          captureError: true,
          error,
        });
      },
      skip() {
        return !this.users.length;
      },
    },
  },
  computed: {
    groupCountsLoading() {
      return this.$apollo.queries.groupCounts.loading;
    },
  },
  i18n: {
    groupCountFetchError: s__(
      'AdminUsers|Could not load user group counts. Please refresh the page to try again.',
    ),
  },
};
</script>

<template>
  <div>
    <users-table
      :users="users"
      :admin-user-path="paths.adminUser"
      :group-counts="groupCounts"
      :group-counts-loading="groupCountsLoading"
    >
      <template #user-actions="{ user }">
        <user-actions :user="user" :paths="paths" :show-button-labels="true" />
      </template>
    </users-table>
  </div>
</template>

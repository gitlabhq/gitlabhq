<script>
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import getUsersMembershipCountsQuery from '../graphql/queries/get_users_membership_counts.query.graphql';
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
      membershipCounts: {},
    };
  },
  apollo: {
    membershipCounts: {
      query: getUsersMembershipCountsQuery,
      variables() {
        return {
          usernames: this.users.map((user) => user.username),
        };
      },
      update(data) {
        const nodes = data?.users?.nodes || [];
        const parsedIds = convertNodeIdsFromGraphQLIds(nodes);

        return parsedIds.reduce((acc, { id, groupCount, projectCount }) => {
          acc[id] = { groupCount, projectCount };
          return acc;
        }, {});
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.membershipCountFetchError,
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
    membershipCountsLoading() {
      return this.$apollo.queries.membershipCounts.loading;
    },
  },
  i18n: {
    membershipCountFetchError: s__(
      'AdminUsers|Could not load user membership counts. Please refresh the page to try again.',
    ),
  },
};
</script>

<template>
  <div>
    <users-table
      :users="users"
      :admin-user-path="paths.adminUser"
      :membership-counts-loading="membershipCountsLoading"
      :membership-counts="membershipCounts"
    >
      <template #user-actions="{ user }">
        <user-actions :user="user" :paths="paths" :show-button-labels="true" show-spacer />
      </template>
    </users-table>
  </div>
</template>

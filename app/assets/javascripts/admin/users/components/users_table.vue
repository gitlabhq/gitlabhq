<script>
import { GlSkeletonLoader, GlTable } from '@gitlab/ui';
import createFlash from '~/flash';
import { convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';
import { thWidthClass } from '~/lib/utils/table_utility';
import { s__, __ } from '~/locale';
import UserDate from '~/vue_shared/components/user_date.vue';
import getUsersGroupCountsQuery from '../graphql/queries/get_users_group_counts.query.graphql';
import UserActions from './user_actions.vue';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    GlSkeletonLoader,
    GlTable,
    UserAvatar,
    UserActions,
    UserDate,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      groupCounts: [],
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
        createFlash({
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
  i18n: {
    groupCountFetchError: s__(
      'AdminUsers|Could not load user group counts. Please refresh the page to try again.',
    ),
  },
  fields: [
    {
      key: 'name',
      label: __('Name'),
      thClass: thWidthClass(40),
    },
    {
      key: 'projectsCount',
      label: __('Projects'),
      thClass: thWidthClass(10),
    },
    {
      key: 'groupCount',
      label: __('Groups'),
      thClass: thWidthClass(10),
    },
    {
      key: 'createdAt',
      label: __('Created on'),
      thClass: thWidthClass(15),
    },
    {
      key: 'lastActivityOn',
      label: __('Last activity'),
      thClass: thWidthClass(15),
    },
    {
      key: 'settings',
      label: '',
      thClass: thWidthClass(10),
    },
  ],
};
</script>

<template>
  <div>
    <gl-table
      :items="users"
      :fields="$options.fields"
      :empty-text="s__('AdminUsers|No users found')"
      show-empty
      stacked="md"
      :tbody-tr-attr="{ 'data-qa-selector': 'user_row_content' }"
    >
      <template #cell(name)="{ item: user }">
        <user-avatar :user="user" :admin-user-path="paths.adminUser" />
      </template>

      <template #cell(createdAt)="{ item: { createdAt } }">
        <user-date :date="createdAt" />
      </template>

      <template #cell(lastActivityOn)="{ item: { lastActivityOn } }">
        <user-date :date="lastActivityOn" show-never />
      </template>

      <template #cell(groupCount)="{ item: { id } }">
        <div :data-testid="`user-group-count-${id}`">
          <gl-skeleton-loader v-if="$apollo.loading" :width="40" :lines="1" />
          <span v-else>{{ groupCounts[id] }}</span>
        </div>
      </template>

      <template #cell(projectsCount)="{ item: { id, projectsCount } }">
        <div :data-testid="`user-project-count-${id}`">{{ projectsCount }}</div>
      </template>

      <template #cell(settings)="{ item: user }">
        <user-actions :user="user" :paths="paths" />
      </template>
    </gl-table>
  </div>
</template>

<script>
import NO_USERS_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-user-settings-md.svg';
import { GlSkeletonLoader, GlTable, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';
import UserDate from '~/vue_shared/components/user_date.vue';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    GlSkeletonLoader,
    GlTable,
    UserAvatar,
    UserDate,
    GlEmptyState,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    adminUserPath: {
      type: String,
      required: true,
    },
    groupCounts: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    groupCountsLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  fields: [
    {
      key: 'name',
      label: __('Name'),
      thClass: 'gl-w-8/20',
    },
    {
      key: 'projectsCount',
      label: __('Projects'),
      thClass: 'gl-w-2/20',
    },
    {
      key: 'groupCount',
      label: __('Groups'),
      thClass: 'gl-w-2/20',
    },
    {
      key: 'createdAt',
      label: __('Created on'),
      thClass: 'gl-w-3/20',
    },
    {
      key: 'lastActivityOn',
      label: __('Last activity'),
      thClass: 'gl-w-3/20',
    },
    {
      key: 'settings',
      label: '',
      thClass: 'gl-w-2/20',
    },
  ],
  NO_USERS_SVG,
};
</script>

<template>
  <gl-table
    v-if="users.length > 0"
    :items="users"
    :fields="$options.fields"
    stacked="md"
    :tbody-tr-attr="{ 'data-testid': 'user-row-content' }"
  >
    <template #cell(name)="{ item: user }">
      <user-avatar :user="user" :admin-user-path="adminUserPath" />
    </template>

    <template #cell(createdAt)="{ item: { createdAt } }">
      <user-date :date="createdAt" />
    </template>

    <template #cell(lastActivityOn)="{ item: { lastActivityOn } }">
      <user-date :date="lastActivityOn" show-never />
    </template>

    <template #cell(groupCount)="{ item: { id } }">
      <div :data-testid="`user-group-count-${id}`">
        <gl-skeleton-loader v-if="groupCountsLoading" :width="40" :lines="1" />
        <span v-else>{{ groupCounts[id] || 0 }}</span>
      </div>
    </template>

    <template #cell(projectsCount)="{ item: { id, projectsCount } }">
      <div :data-testid="`user-project-count-${id}`">
        {{ projectsCount || 0 }}
      </div>
    </template>

    <template #cell(settings)="{ item: user }">
      <slot name="user-actions" :user="user"></slot>
    </template>
  </gl-table>
  <gl-empty-state
    v-else
    :svg-path="$options.NO_USERS_SVG"
    :title="s__('AdminUsers|No users found')"
  />
</template>

<script>
import NO_USERS_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-user-settings-md.svg';
import { GlSkeletonLoader, GlTable } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import UserAvatar from './user_avatar.vue';
import {
  FIELD_NAME,
  FIELD_ORGANIZATION_ROLE,
  FIELD_PROJECTS_COUNT,
  FIELD_GROUP_COUNT,
  FIELD_CREATED_AT,
  FIELD_LAST_ACTIVITY_ON,
  FIELD_SETTINGS,
} from './constants';

export default {
  components: {
    GlSkeletonLoader,
    GlTable,
    UserAvatar,
    UserDate,
    EmptyResult,
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
    fieldsToRender: {
      type: Array,
      required: false,
      default() {
        return [
          FIELD_NAME,
          FIELD_PROJECTS_COUNT,
          FIELD_GROUP_COUNT,
          FIELD_CREATED_AT,
          FIELD_LAST_ACTIVITY_ON,
          FIELD_SETTINGS,
        ];
      },
    },
    columnWidths: {
      type: Object,
      required: false,
      default() {
        return {
          [FIELD_NAME]: 'gl-w-8/20',
          [FIELD_PROJECTS_COUNT]: 'gl-w-2/20',
          [FIELD_GROUP_COUNT]: 'gl-w-2/20',
          [FIELD_CREATED_AT]: 'gl-w-3/20',
          [FIELD_LAST_ACTIVITY_ON]: 'gl-w-3/20',
          [FIELD_SETTINGS]: 'gl-w-2/20',
        };
      },
    },
  },
  computed: {
    availableFields() {
      return [
        {
          key: FIELD_NAME,
          label: __('Name'),
          thClass: this.columnWidths[FIELD_NAME],
          isRowHeader: true,
        },
        {
          key: FIELD_ORGANIZATION_ROLE,
          label: s__('Organization|Organization role'),
          thClass: this.columnWidths[FIELD_ORGANIZATION_ROLE],
        },
        {
          key: FIELD_PROJECTS_COUNT,
          label: __('Projects'),
          thClass: this.columnWidths[FIELD_PROJECTS_COUNT],
        },
        {
          key: FIELD_GROUP_COUNT,
          label: __('Groups'),
          thClass: this.columnWidths[FIELD_GROUP_COUNT],
        },
        {
          key: FIELD_CREATED_AT,
          label: __('Created on'),
          thClass: this.columnWidths[FIELD_CREATED_AT],
        },
        {
          key: FIELD_LAST_ACTIVITY_ON,
          label: __('Last activity'),
          thClass: this.columnWidths[FIELD_LAST_ACTIVITY_ON],
        },
        {
          key: FIELD_SETTINGS,
          label: '',
          thClass: this.columnWidths[FIELD_SETTINGS],
        },
      ];
    },
    fields() {
      return this.availableFields.filter((field) => this.fieldsToRender.includes(field.key));
    },
  },
  NO_USERS_SVG,
};
</script>

<template>
  <gl-table
    v-if="users.length > 0"
    :items="users"
    :fields="fields"
    stacked="md"
    :tbody-tr-attr="{ 'data-testid': 'user-row-content' }"
  >
    <template #cell(name)="{ item: user }">
      <user-avatar :user="user" :admin-user-path="adminUserPath" class="gl-font-normal" />
    </template>

    <template v-if="$scopedSlots['organization-role']" #cell(organizationRole)="{ item: user }">
      <slot name="organization-role" :user="user"></slot>
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
  <empty-result v-else />
</template>

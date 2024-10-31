<script>
import { GlLoadingIcon, GlKeysetPagination, GlCollapsibleListbox } from '@gitlab/ui';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import {
  FIELD_NAME,
  FIELD_ORGANIZATION_ROLE,
  FIELD_CREATED_AT,
  FIELD_LAST_ACTIVITY_ON,
} from '~/vue_shared/components/users_table/constants';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';
import { __ } from '~/locale';

export default {
  name: 'UsersView',
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    GlCollapsibleListbox,
    UsersTable,
  },
  inject: ['paths'],
  roleListboxItems: [
    {
      text: __('User'),
      value: ACCESS_LEVEL_DEFAULT.toUpperCase(),
    },
    {
      text: __('Owner'),
      value: ACCESS_LEVEL_OWNER.toUpperCase(),
    },
  ],
  usersTable: {
    fieldsToRender: [FIELD_NAME, FIELD_ORGANIZATION_ROLE, FIELD_CREATED_AT, FIELD_LAST_ACTIVITY_ON],
    columnWidths: {
      [FIELD_ORGANIZATION_ROLE]: 'gl-w-20',
    },
  },
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
  methods: {
    roleListboxItemText(accessLevel) {
      return this.$options.roleListboxItems.find((item) => item.value === accessLevel).text;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
    <template v-else>
      <users-table
        :users="users"
        :admin-user-path="paths.adminUser"
        :fields-to-render="$options.usersTable.fieldsToRender"
        :column-widths="$options.usersTable.columnWidths"
      >
        <template #organization-role="{ user }">
          <gl-collapsible-listbox
            :selected="user.accessLevel.stringValue"
            block
            toggle-class="gl-form-input-xl"
            :items="$options.roleListboxItems"
          />
        </template>
      </users-table>
      <div class="gl-flex gl-justify-center">
        <gl-keyset-pagination v-bind="pageInfo" @prev="$emit('prev')" @next="$emit('next')" />
      </div>
    </template>
  </div>
</template>

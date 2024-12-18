<script>
import { GlButton, GlLoadingIcon, GlKeysetPagination, GlTooltipDirective } from '@gitlab/ui';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import UserDetailsDrawer from '~/organizations/users/components/user_details_drawer.vue';
import {
  FIELD_NAME,
  FIELD_ORGANIZATION_ROLE,
  FIELD_CREATED_AT,
  FIELD_LAST_ACTIVITY_ON,
} from '~/vue_shared/components/users_table/constants';
import {
  ACCESS_LEVEL_DEFAULT,
  ACCESS_LEVEL_OWNER,
  ACCESS_LEVEL_LABEL,
} from '~/organizations/shared/constants';
import { __, s__ } from '~/locale';

export default {
  name: 'UsersView',
  i18n: {
    errorMessage: s__(
      'Organization|An error occurred updating the organization role. Please try again.',
    ),
    successMessage: s__('Organization|Organization role was updated successfully.'),
    disabledRoleListboxTooltipText: s__('Organization|Organizations must have at least one owner.'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlLoadingIcon,
    GlKeysetPagination,
    UsersTable,
    UserDetailsDrawer,
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
  data() {
    return {
      userDetailsDrawerActiveUser: null,
      userDetailsDrawerLoading: false,
    };
  },
  methods: {
    setUserDetailsDrawerActiveUser(user) {
      this.userDetailsDrawerActiveUser = user;
    },
    setUserDetailsDrawerLoading(loading) {
      this.userDetailsDrawerLoading = loading;
    },
    onRoleChange() {
      this.$emit('role-change');
    },
    userAccessLevelLabel(user) {
      return ACCESS_LEVEL_LABEL[user.accessLevel.stringValue];
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
          <gl-button
            class="gl-block"
            variant="link"
            :disabled="userDetailsDrawerLoading"
            @click="setUserDetailsDrawerActiveUser(user)"
          >
            {{ userAccessLevelLabel(user) }}
          </gl-button>
        </template>
      </users-table>
      <div class="gl-flex gl-justify-center">
        <gl-keyset-pagination v-bind="pageInfo" @prev="$emit('prev')" @next="$emit('next')" />
      </div>
    </template>
    <user-details-drawer
      :user="userDetailsDrawerActiveUser"
      @loading="setUserDetailsDrawerLoading"
      @close="setUserDetailsDrawerActiveUser(null)"
      @role-change="onRoleChange"
    />
  </div>
</template>

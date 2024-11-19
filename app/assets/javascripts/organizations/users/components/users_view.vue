<script>
import {
  GlLoadingIcon,
  GlKeysetPagination,
  GlCollapsibleListbox,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import {
  FIELD_NAME,
  FIELD_ORGANIZATION_ROLE,
  FIELD_CREATED_AT,
  FIELD_LAST_ACTIVITY_ON,
} from '~/vue_shared/components/users_table/constants';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';
import { __, s__ } from '~/locale';
import organizationUserUpdateMutation from '../graphql/mutations/organization_user_update.mutation.graphql';

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
  data() {
    return {
      roleListboxLoadingStates: [],
    };
  },
  methods: {
    async onRoleSelect(accessLevel, user) {
      this.roleListboxLoadingStates.push(user.gid);

      try {
        const {
          data: {
            organizationUserUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUserUpdateMutation,
          variables: {
            input: {
              id: user.gid,
              accessLevel,
            },
          },
        });

        if (errors.length) {
          createAlert({ message: errors[0] });

          return;
        }

        this.$toast.show(this.$options.i18n.successMessage);
        this.$emit('role-change');
      } catch (error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      } finally {
        this.roleListboxLoadingStates.splice(this.roleListboxLoadingStates.indexOf(user.gid), 1);
      }
    },
    roleListboxItemText(accessLevel) {
      return this.$options.roleListboxItems.find((item) => item.value === accessLevel).text;
    },
    isRoleListboxDisabled(user) {
      return user.isLastOwner;
    },
    roleListboxTooltip(user) {
      return this.isRoleListboxDisabled(user)
        ? this.$options.i18n.disabledRoleListboxTooltipText
        : null;
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
          <div
            v-gl-tooltip="{ disabled: !roleListboxTooltip(user), title: roleListboxTooltip(user) }"
            class="gl-rounded-base focus:gl-focus"
            :tabindex="isRoleListboxDisabled(user) && 0"
          >
            <gl-collapsible-listbox
              :disabled="isRoleListboxDisabled(user)"
              :selected="user.accessLevel.stringValue"
              block
              toggle-class="gl-form-input-xl"
              :items="$options.roleListboxItems"
              :loading="roleListboxLoadingStates.includes(user.gid)"
              @select="onRoleSelect($event, user)"
            />
          </div>
        </template>
      </users-table>
      <div class="gl-flex gl-justify-center">
        <gl-keyset-pagination v-bind="pageInfo" @prev="$emit('prev')" @next="$emit('next')" />
      </div>
    </template>
  </div>
</template>

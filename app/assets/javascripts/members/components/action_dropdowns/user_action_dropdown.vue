<script>
import { GlDropdown, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import { I18N } from './constants';
import LeaveGroupDropdownItem from './leave_group_dropdown_item.vue';
import RemoveMemberDropdownItem from './remove_member_dropdown_item.vue';

export default {
  name: 'UserActionDropdown',
  i18n: I18N,
  components: {
    GlDropdown,
    LdapOverrideDropdownItem: () =>
      import('ee_component/members/components/ldap/ldap_override_dropdown_item.vue'),
    LeaveGroupDropdownItem,
    RemoveMemberDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  computed: {
    modalMessage() {
      const { user, source } = this.member;

      if (user) {
        return sprintf(
          this.$options.i18n.confirmNormalUserRemoval,
          { userName: user.name, group: source.fullName },
          false,
        );
      }

      return sprintf(this.$options.i18n.confirmOrphanedUserRemoval, { group: source.fullName });
    },
    userDeletionObstaclesUserData() {
      return {
        name: this.member.user?.name,
        obstacles: parseUserDeletionObstacles(this.member.user),
      };
    },
    showDropdown() {
      return this.permissions.canRemove || this.showLdapOverride;
    },
    showLdapOverride() {
      return this.permissions.canOverride && !this.member.isOverridden;
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="showDropdown"
    v-gl-tooltip="$options.i18n.actions"
    :text="$options.i18n.actions"
    text-sr-only
    icon="ellipsis_v"
    category="tertiary"
    no-caret
    right
    data-testid="user-action-dropdown"
    data-qa-selector="user_action_dropdown"
  >
    <template v-if="permissions.canRemove">
      <leave-group-dropdown-item v-if="isCurrentUser" :member="member">{{
        $options.i18n.leaveGroup
      }}</leave-group-dropdown-item>
      <remove-member-dropdown-item
        v-else
        :member-id="member.id"
        :member-model-type="member.type"
        :user-deletion-obstacles="userDeletionObstaclesUserData"
        :modal-message="modalMessage"
        >{{ $options.i18n.removeMember }}</remove-member-dropdown-item
      >
    </template>
    <ldap-override-dropdown-item v-else-if="showLdapOverride" :member="member">{{
      $options.i18n.editPermissions
    }}</ldap-override-dropdown-item>
  </gl-dropdown>
</template>

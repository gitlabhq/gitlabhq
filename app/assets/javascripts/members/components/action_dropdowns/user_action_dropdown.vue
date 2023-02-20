<script>
import { GlDropdown, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import {
  MEMBER_MODEL_TYPE_GROUP_MEMBER,
  MEMBER_MODEL_TYPE_PROJECT_MEMBER,
} from '~/members/constants';
import { I18N } from './constants';
import LeaveGroupDropdownItem from './leave_group_dropdown_item.vue';
import RemoveMemberDropdownItem from './remove_member_dropdown_item.vue';

export default {
  name: 'UserActionDropdown',
  i18n: I18N,
  components: {
    GlDropdown,
    DisableTwoFactorDropdownItem: () =>
      import(
        'ee_component/members/components/action_dropdowns/disable_two_factor_dropdown_item.vue'
      ),
    LdapOverrideDropdownItem: () =>
      import('ee_component/members/components/action_dropdowns/ldap_override_dropdown_item.vue'),
    LeaveGroupDropdownItem,
    RemoveMemberDropdownItem,
    BanMemberDropdownItem: () =>
      import('ee_component/members/components/action_dropdowns/ban_member_dropdown_item.vue'),
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
    modalDisableTwoFactor() {
      const userName = this.member.user.username;
      return sprintf(this.$options.i18n.confirmDisableTwoFactor, { userName }, false);
    },
    modalRemoveUser() {
      const { user, source } = this.member;

      if (this.permissions.canRemoveBlockedByLastOwner) {
        if (this.member.type === MEMBER_MODEL_TYPE_PROJECT_MEMBER) {
          return I18N.personalProjectOwnerCannotBeRemoved;
        }

        if (this.member.type === MEMBER_MODEL_TYPE_GROUP_MEMBER) {
          return I18N.lastGroupOwnerCannotBeRemoved;
        }
      }

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
      return (
        this.permissions.canDisableTwoFactor ||
        this.showLeaveOrRemove ||
        this.showLdapOverride ||
        this.showBan
      );
    },
    showLeaveOrRemove() {
      return this.permissions.canRemove || this.permissions.canRemoveBlockedByLastOwner;
    },
    showLdapOverride() {
      return this.permissions.canOverride && !this.member.isOverridden;
    },
    showBan() {
      return !this.isCurrentUser && this.permissions.canBan;
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
    <disable-two-factor-dropdown-item
      v-if="permissions.canDisableTwoFactor"
      :modal-message="modalDisableTwoFactor"
      :user-id="member.user.id"
    >
      {{ $options.i18n.disableTwoFactor }}
    </disable-two-factor-dropdown-item>

    <template v-if="showLeaveOrRemove">
      <leave-group-dropdown-item v-if="isCurrentUser" :member="member" :permissions="permissions">{{
        $options.i18n.leaveGroup
      }}</leave-group-dropdown-item>

      <remove-member-dropdown-item
        v-else
        :member-id="member.id"
        :member-model-type="member.type"
        :user-deletion-obstacles="userDeletionObstaclesUserData"
        :modal-message="modalRemoveUser"
        :prevent-removal="permissions.canRemoveBlockedByLastOwner"
        >{{ $options.i18n.removeMember }}</remove-member-dropdown-item
      >
    </template>

    <ldap-override-dropdown-item v-else-if="showLdapOverride" :member="member">{{
      $options.i18n.editPermissions
    }}</ldap-override-dropdown-item>
    <ban-member-dropdown-item v-if="showBan" :member="member">{{
      $options.i18n.banMember
    }}</ban-member-dropdown-item>
  </gl-dropdown>
</template>

<script>
import { GlBadge, GlCollapsibleListbox, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { guestOverageConfirmAction } from 'ee_else_ce/members/guest_overage_confirm_action';
import {
  roleDropdownItems,
  initialSelectedRole,
  handleMemberRoleUpdate,
} from 'ee_else_ce/members/utils';
import { ACCESS_LEVEL_LABELS } from '~/access_level/constants';
import { s__ } from '~/locale';
import { logError } from '~/lib/logger';

export default {
  components: {
    GlCollapsibleListbox,
    GlBadge,
    LdapDropdownFooter: () =>
      import('ee_component/members/components/action_dropdowns/ldap_dropdown_footer.vue'),
    ManageRolesDropdownFooter: () =>
      import('ee_component/members/components/action_dropdowns/manage_roles_dropdown_footer.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespace', 'group'],
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  data() {
    const accessLevelOptions = roleDropdownItems(this.member);
    return {
      accessLevelOptions,
      busy: false,
      isDesktop: false,
      memberRoleId: this.member.accessLevel.memberRoleId ?? null,
      selectedRole: initialSelectedRole(accessLevelOptions.flatten, this.member)?.value,
    };
  },
  computed: {
    disabled() {
      return this.permissions.canOverride && !this.member.isOverridden;
    },
  },
  mounted() {
    this.isDesktop = bp.isDesktop();
  },
  methods: {
    ...mapActions({
      updateMemberRole(dispatch, { memberId, accessLevel, memberRoleId }) {
        return dispatch(`${this.namespace}/updateMemberRole`, {
          memberId,
          accessLevel,
          memberRoleId,
        });
      },
    }),
    async handleSelect(value) {
      this.busy = true;

      const newRole = this.accessLevelOptions.flatten.find((item) => item.value === value);
      const previousRole = this.selectedRole;
      const previousMemberRoleId = this.memberRoleId;

      try {
        const confirmed = await guestOverageConfirmAction({
          oldAccessLevel: this.member.accessLevel.integerValue,
          newRoleName: ACCESS_LEVEL_LABELS[newRole.accessLevel],
          newMemberRoleId: newRole.memberRoleId,
          group: this.group,
          memberId: this.member.id,
          memberType: this.namespace,
        });
        if (!confirmed) {
          return;
        }

        this.selectedRole = value;
        this.memberRoleId = newRole.memberRoleId;

        const response = await this.updateMemberRole({
          memberId: this.member.id,
          accessLevel: newRole.accessLevel,
          memberRoleId: newRole.memberRoleId,
        });

        // EE has a flow where role change is not immediate but goes through an approval process.
        // In that case we should restore previously selected user role
        this.selectedRole = handleMemberRoleUpdate({
          currentRole: previousRole,
          requestedRole: newRole.value,
          response,
        });
      } catch (error) {
        this.selectedRole = previousRole;
        this.memberRoleId = previousMemberRoleId;
        logError(error);
        Sentry.captureException(error);
      } finally {
        this.busy = false;
      }
    },
  },
  i18n: {
    customRole: s__('MemberRole|Custom role'),
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      v-if="permissions.canUpdate"
      :placement="isDesktop ? 'bottom-start' : 'bottom-end'"
      :header-text="__('Change role')"
      :disabled="disabled"
      :loading="busy"
      data-testid="access-level-dropdown"
      :items="accessLevelOptions.formatted"
      :selected="selectedRole"
      @select="handleSelect"
    >
      <template #list-item="{ item }">
        <div data-testid="access-level-link" :class="{ 'gl-font-bold': item.memberRoleId }">
          {{ item.text }}
        </div>
        <div
          v-if="item.memberRoleId && item.description"
          class="gl-line-clamp-2 gl-whitespace-normal gl-pt-1 gl-text-sm gl-text-subtle"
        >
          {{ item.description }}
        </div>
      </template>
      <template #footer>
        <ldap-dropdown-footer
          v-if="permissions.canOverride && member.isOverridden"
          :member-id="member.id"
        />
        <manage-roles-dropdown-footer />
      </template>
    </gl-collapsible-listbox>

    <div v-else v-gl-tooltip.ds0="member.accessLevel.description" data-testid="role-text">
      {{ member.accessLevel.stringValue }}
    </div>

    <gl-badge v-if="memberRoleId" class="gl-mt-3">{{ $options.i18n.customRole }}</gl-badge>
  </div>
</template>

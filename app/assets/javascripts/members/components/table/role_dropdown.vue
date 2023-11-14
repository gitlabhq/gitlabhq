<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { guestOverageConfirmAction } from 'ee_else_ce/members/guest_overage_confirm_action';
import { roleDropdownItems, initialSelectedRole } from 'ee_else_ce/members/utils';
import { s__ } from '~/locale';

export default {
  name: 'RoleDropdown',
  components: {
    GlCollapsibleListbox,
    LdapDropdownFooter: () =>
      import('ee_component/members/components/action_dropdowns/ldap_dropdown_footer.vue'),
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
    return {
      isDesktop: false,
      busy: false,
      selectedRole: null,
    };
  },
  computed: {
    disabled() {
      return this.permissions.canOverride && !this.member.isOverridden;
    },
    dropdownItems() {
      return roleDropdownItems(this.member);
    },
  },
  created() {
    this.selectedRole = initialSelectedRole(this.dropdownItems.flatten, this.member);
  },
  mounted() {
    this.isDesktop = bp.isDesktop();
  },
  methods: {
    ...mapActions({
      updateMemberRole(dispatch, payload) {
        return dispatch(`${this.namespace}/updateMemberRole`, payload);
      },
    }),
    async handleSelect(value) {
      this.busy = true;

      const newRole = this.dropdownItems.flatten.find((item) => item.value === value);
      const previousRole = this.selectedRole;

      try {
        const confirmed = await guestOverageConfirmAction({
          currentRoleValue: this.member.accessLevel.integerValue,
          newRoleValue: newRole.accessLevel,
          newRoleName: newRole.text,
          newMemberRoleId: newRole.memberRoleId,
          group: this.group,
          memberId: this.member.id,
          memberType: this.namespace,
        });
        if (!confirmed) {
          return;
        }

        this.selectedRole = value;

        await this.updateMemberRole({
          memberId: this.member.id,
          accessLevel: {
            integerValue: newRole.accessLevel,
            memberRoleId: newRole.memberRoleId,
          },
        });

        this.$toast.show(s__('Members|Role updated successfully.'));
      } catch (error) {
        this.selectedRole = previousRole;
        Sentry.captureException(error);
      } finally {
        this.busy = false;
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :placement="isDesktop ? 'left' : 'right'"
    :toggle-text="member.accessLevel.stringValue"
    :header-text="__('Change role')"
    :disabled="disabled"
    :loading="busy"
    data-qa-selector="access_level_dropdown"
    :items="dropdownItems.formatted"
    :selected="selectedRole"
    @select="handleSelect"
  >
    <template #list-item="{ item }">
      <span data-qa-selector="access_level_link">{{ item.text }}</span>
    </template>
    <template #footer>
      <ldap-dropdown-footer
        v-if="permissions.canOverride && member.isOverridden"
        :member-id="member.id"
      />
    </template>
  </gl-collapsible-listbox>
</template>

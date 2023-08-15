<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { guestOverageConfirmAction } from 'ee_else_ce/members/guest_overage_confirm_action';

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
      selectedRoleValue: this.member.accessLevel.integerValue,
    };
  },
  computed: {
    disabled() {
      return this.permissions.canOverride && !this.member.isOverridden;
    },
    dropdownItems() {
      return Object.entries(this.member.validRoles).map(([name, value]) => ({
        value,
        text: name,
      }));
    },
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
    async handleOverageConfirm(currentRoleValue, newRoleValue, newRoleName) {
      return guestOverageConfirmAction({
        currentRoleValue,
        newRoleValue,
        newRoleName,
        group: this.group,
        memberId: this.member.id,
        memberType: this.namespace,
      });
    },
    async handleSelect(newRoleValue) {
      const currentRoleValue = this.member.accessLevel.integerValue;
      if (newRoleValue === currentRoleValue) {
        return;
      }

      this.busy = true;

      const { text: newRoleName } = this.dropdownItems.find((item) => item.value === newRoleValue);
      const confirmed = await this.handleOverageConfirm(
        currentRoleValue,
        newRoleValue,
        newRoleName,
      );
      if (!confirmed) {
        this.selectedRoleValue = currentRoleValue;
        this.busy = false;
        return;
      }

      try {
        await this.updateMemberRole({
          memberId: this.member.id,
          accessLevel: { integerValue: newRoleValue, stringValue: newRoleName },
        });

        this.$toast.show(s__('Members|Role updated successfully.'));
      } catch (error) {
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
    v-model="selectedRoleValue"
    :placement="isDesktop ? 'left' : 'right'"
    :toggle-text="member.accessLevel.stringValue"
    :header-text="__('Change role')"
    :disabled="disabled"
    :loading="busy"
    data-qa-selector="access_level_dropdown"
    :items="dropdownItems"
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

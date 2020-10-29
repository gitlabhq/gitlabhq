<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { mapActions } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'RoleDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    LdapDropdownItem: () =>
      import('ee_component/vue_shared/components/members/ldap/ldap_dropdown_item.vue'),
  },
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
    };
  },
  computed: {
    disabled() {
      return this.busy || (this.permissions.canOverride && !this.member.isOverridden);
    },
  },
  mounted() {
    this.isDesktop = bp.isDesktop();
  },
  methods: {
    ...mapActions(['updateMemberRole']),
    handleSelect(value, name) {
      if (value === this.member.accessLevel.integerValue) {
        return;
      }

      this.busy = true;

      this.updateMemberRole({
        memberId: this.member.id,
        accessLevel: { integerValue: value, stringValue: name },
      })
        .then(() => {
          this.$toast.show(s__('Members|Role updated successfully.'));
          this.busy = false;
        })
        .catch(() => {
          this.busy = false;
        });
    },
  },
};
</script>

<template>
  <gl-dropdown
    :right="!isDesktop"
    :text="member.accessLevel.stringValue"
    :header-text="__('Change permissions')"
    :disabled="disabled"
  >
    <gl-dropdown-item
      v-for="(value, name) in member.validRoles"
      :key="value"
      is-check-item
      :is-checked="value === member.accessLevel.integerValue"
      @click="handleSelect(value, name)"
    >
      {{ name }}
    </gl-dropdown-item>
    <ldap-dropdown-item
      v-if="permissions.canOverride && member.isOverridden"
      :member-id="member.id"
    />
  </gl-dropdown>
</template>

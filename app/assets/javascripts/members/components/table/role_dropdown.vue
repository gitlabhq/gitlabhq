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
    LdapDropdownItem: () => import('ee_component/members/components/ldap/ldap_dropdown_item.vue'),
  },
  inject: ['namespace'],
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

    // Bootstrap Vue and GlDropdown to not support adding attributes to the dropdown toggle
    // This can be changed once https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1060 is implemented
    const dropdownToggle = this.$refs.glDropdown.$el.querySelector('.dropdown-toggle');

    if (dropdownToggle) {
      dropdownToggle.setAttribute('data-qa-selector', 'access_level_dropdown');
    }
  },
  methods: {
    ...mapActions({
      updateMemberRole(dispatch, payload) {
        return dispatch(`${this.namespace}/updateMemberRole`, payload);
      },
    }),
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
    ref="glDropdown"
    :right="!isDesktop"
    :text="member.accessLevel.stringValue"
    :header-text="__('Change role')"
    :disabled="disabled"
  >
    <gl-dropdown-item
      v-for="(value, name) in member.validRoles"
      :key="value"
      is-check-item
      :is-checked="value === member.accessLevel.integerValue"
      data-qa-selector="access_level_link"
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

<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { convertArrayToCamelCase } from '~/lib/utils/common_utils';
import { generateUserPaths } from '../utils';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    },
  },
  computed: {
    userActions() {
      return convertArrayToCamelCase(this.user.actions);
    },
    dropdownActions() {
      return this.userActions.filter((a) => a !== 'edit');
    },
    dropdownDeleteActions() {
      return this.dropdownActions.filter((a) => a.includes('delete'));
    },
    dropdownSafeActions() {
      return this.dropdownActions.filter((a) => !this.dropdownDeleteActions.includes(a));
    },
    hasDropdownActions() {
      return this.dropdownActions.length > 0;
    },
    hasDeleteActions() {
      return this.dropdownDeleteActions.length > 0;
    },
    hasEditAction() {
      return this.userActions.includes('edit');
    },
    userPaths() {
      return generateUserPaths(this.paths, this.user.username);
    },
  },
  methods: {
    isLdapAction(action) {
      return action === 'ldapBlocked';
    },
  },
  i18n: {
    edit: __('Edit'),
    settings: __('Settings'),
    unlock: __('Unlock'),
    block: s__('AdminUsers|Block'),
    unblock: s__('AdminUsers|Unblock'),
    approve: s__('AdminUsers|Approve'),
    reject: s__('AdminUsers|Reject'),
    deactivate: s__('AdminUsers|Deactivate'),
    activate: s__('AdminUsers|Activate'),
    ldapBlocked: s__('AdminUsers|Cannot unblock LDAP blocked users'),
    delete: s__('AdminUsers|Delete user'),
    deleteWithContributions: s__('AdminUsers|Delete user and contributions'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-end">
    <gl-button v-if="hasEditAction" data-testid="edit" :href="userPaths.edit">{{
      $options.i18n.edit
    }}</gl-button>

    <gl-dropdown
      v-if="hasDropdownActions"
      data-testid="actions"
      right
      class="gl-ml-2"
      icon="settings"
    >
      <gl-dropdown-section-header>{{ $options.i18n.settings }}</gl-dropdown-section-header>

      <template v-for="action in dropdownSafeActions">
        <gl-dropdown-item v-if="isLdapAction(action)" :key="action" :data-testid="action">
          {{ $options.i18n.ldap }}
        </gl-dropdown-item>
        <gl-dropdown-item v-else :key="action" :href="userPaths[action]" :data-testid="action">
          {{ $options.i18n[action] }}
        </gl-dropdown-item>
      </template>

      <gl-dropdown-divider v-if="hasDeleteActions" />

      <gl-dropdown-item
        v-for="action in dropdownDeleteActions"
        :key="action"
        :href="userPaths[action]"
        :data-testid="`delete-${action}`"
      >
        <span class="gl-text-red-500">{{ $options.i18n[action] }}</span>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>

<script>
import { GlLink, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ProtectionRow from './protection_row.vue';

export const i18n = {
  rolesTitle: s__('BranchRules|Roles'),
  usersAndGroupsTitle: s__('BranchRules|Users & groups'),
  groupsTitle: s__('BranchRules|Groups'),
};

export default {
  name: 'ProtectionDetail',
  i18n,
  components: { GlLink, GlButton, ProtectionRow, CrudComponent },
  mixins: [glFeatureFlagsMixin()],
  props: {
    header: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: false,
      default: 'shield',
    },
    count: {
      type: Number,
      required: false,
      default: null,
    },
    headerLinkTitle: {
      type: String,
      required: true,
    },
    headerLinkHref: {
      type: String,
      required: true,
    },
    roles: {
      type: Array,
      required: false,
      default: () => [],
    },
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    groups: {
      type: Array,
      required: false,
      default: () => [],
    },
    statusChecks: {
      type: Array,
      required: false,
      default: () => [],
    },
    isEditAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyStateCopy: {
      type: String,
      required: true,
    },
    helpText: {
      type: String,
      required: false,
      default: () => '',
    },
  },
  computed: {
    hasRoles() {
      return Boolean(this.roles.length);
    },
    hasUsers() {
      return Boolean(this.users.length);
    },
    hasGroups() {
      return Boolean(this.groups.length);
    },
    hasStatusChecks() {
      return Boolean(this.statusChecks.length);
    },
    showDivider() {
      return this.hasRoles || this.hasUsers;
    },
    showEmptyState() {
      return !this.hasRoles && !this.hasUsers && !this.hasGroups && !this.hasStatusChecks;
    },
    showHelpText() {
      return Boolean(this.helpText.length);
    },
  },
};
</script>

<template>
  <crud-component :title="header" :icon="icon" :count="count" data-testid="status-checks">
    <template v-if="showHelpText" #description>
      {{ helpText }}
    </template>
    <template #actions>
      <gl-button
        v-if="glFeatures.editBranchRules && isEditAvailable"
        size="small"
        data-testid="edit-rule-button"
        @click="$emit('edit')"
        >{{ __('Edit') }}
      </gl-button>
      <gl-link v-else :href="headerLinkHref">{{ headerLinkTitle }}</gl-link>
    </template>
    <span v-if="showEmptyState" class="gl-text-subtle" data-testid="protection-empty-state">
      {{ emptyStateCopy }}
    </span>

    <!-- Roles -->
    <protection-row v-if="roles.length" :title="$options.i18n.rolesTitle" :access-levels="roles" />

    <!-- Users and Groups -->
    <protection-row
      v-if="hasUsers || hasGroups"
      :show-divider="hasRoles"
      :users="users"
      :groups="groups"
      :title="$options.i18n.usersAndGroupsTitle"
    />

    <!-- Status checks -->
    <protection-row
      v-for="(statusCheck, index) in statusChecks"
      :key="statusCheck.id"
      :show-divider="index !== 0"
      :title="statusCheck.name"
      :status-check-url="statusCheck.externalUrl"
      :hmac="statusCheck.hmac"
    />
  </crud-component>
</template>

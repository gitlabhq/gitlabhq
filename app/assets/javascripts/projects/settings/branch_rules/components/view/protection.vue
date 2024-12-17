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
  deployKeysTitle: s__('BranchRules|Deploy keys'),
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
      required: false,
      default: null,
    },
    headerLinkHref: {
      type: String,
      required: false,
      default: null,
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
    deployKeys: {
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
    hasDeployKeys() {
      return Boolean(this.deployKeys.length);
    },
    hasStatusChecks() {
      return Boolean(this.statusChecks.length);
    },
    showDivider() {
      return this.hasRoles || this.hasUsers;
    },
    showEmptyState() {
      return (
        !this.hasRoles &&
        !this.hasUsers &&
        !this.hasGroups &&
        !this.hasStatusChecks &&
        !this.hasDeployKeys
      );
    },
    showDescriptionSlot() {
      return this.helpText || this.$scopedSlots.description;
    },
  },
};
</script>

<template>
  <crud-component :title="header" :icon="icon" :count="count" data-testid="status-checks">
    <template v-if="showDescriptionSlot" #description>
      <slot v-if="$scopedSlots.description" name="description"></slot>
      <template v-else>{{ helpText }}</template>
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
    <span
      v-if="showEmptyState && !$scopedSlots.content"
      class="gl-text-subtle"
      data-testid="protection-empty-state"
    >
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

    <!-- Deploy keys -->
    <protection-row
      v-if="hasDeployKeys"
      :show-divider="showDivider"
      :deploy-keys="deployKeys"
      :title="$options.i18n.deployKeysTitle"
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

    <slot name="content"></slot>
  </crud-component>
</template>

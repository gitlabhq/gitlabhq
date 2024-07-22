<script>
import { GlCard, GlLink, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ProtectionRow from './protection_row.vue';

export const i18n = {
  rolesTitle: s__('BranchRules|Roles'),
  usersAndGroupsTitle: s__('BranchRules|Users & groups'),
  groupsTitle: s__('BranchRules|Groups'),
};

export default {
  name: 'ProtectionDetail',
  i18n,
  components: { GlCard, GlLink, GlButton, ProtectionRow },
  mixins: [glFeatureFlagsMixin()],
  props: {
    header: {
      type: String,
      required: true,
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
  <gl-card
    class="gl-new-card gl-mb-5"
    header-class="gl-new-card-header gl-flex-wrap"
    body-class="gl-new-card-body gl-px-5 gl-pt-4"
  >
    <template #header>
      <strong>{{ header }}</strong>
      <gl-button
        v-if="glFeatures.editBranchRules && isEditAvailable"
        size="small"
        data-testid="edit-rule-button"
        @click="$emit('edit')"
        >{{ __('Edit') }}</gl-button
      >
      <gl-link v-else :href="headerLinkHref">{{ headerLinkTitle }}</gl-link>
      <p v-if="showHelpText" class="gl-mb-0 gl-basis-full gl-text-secondary">
        {{ helpText }}
      </p></template
    >

    <p v-if="showEmptyState" class="gl-text-secondary" data-testid="protection-empty-state">
      {{ emptyStateCopy }}
    </p>

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
    />
  </gl-card>
</template>

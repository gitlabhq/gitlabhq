<script>
import { GlToggle, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';
import { REQUIRED_ICON, NOT_REQUIRED_ICON } from './constants';
import DisabledByPolicyPopover from './disabled_by_policy_popover.vue';

export default {
  components: {
    GlToggle,
    GlIcon,
    GlSprintf,
    GlLink,
    GroupInheritancePopover,
    DisabledByPolicyPopover,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    canAdminProtectedBranches: { default: false },
    canAdminGroupProtectedBranches: { default: false },
    groupSettingsRepositoryPath: { default: '' },
  },
  props: {
    dataTestIdPrefix: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    descriptionLink: {
      type: String,
      required: false,
      default: '',
    },
    help: {
      type: String,
      required: false,
      default: '',
    },
    iconTitle: {
      type: String,
      required: true,
    },
    isProtected: {
      type: Boolean,
      required: true,
    },
    isProtectedByPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProtectedByWarnPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isGroupLevel: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isProtectedByAnyPolicyType() {
      return this.isProtectedByPolicy || this.isProtectedByWarnPolicy;
    },
    toggleDisabled() {
      return this.isGroupLevel || this.isProtectedByPolicy;
    },
    iconName() {
      return this.isProtected ? REQUIRED_ICON : NOT_REQUIRED_ICON;
    },
    iconVariant() {
      return this.isProtected ? 'success' : 'danger';
    },
    iconDataTestId() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return this.dataTestIdPrefix ? `${this.dataTestIdPrefix}-icon` : '';
    },
    hasDescription() {
      return this.isProtected ? Boolean(this.description) : false;
    },
    canEditProtectionToggles() {
      return this.canAdminProtectedBranches;
    },
  },
};
</script>

<template>
  <div v-if="canEditProtectionToggles">
    <gl-toggle
      :label="label"
      :help="help"
      :value="isProtected"
      :is-loading="isLoading"
      :disabled="toggleDisabled"
      class="gl-flex-grow-1 gl-mb-5"
      @change="$emit('toggle', $event)"
    >
      <template #label>
        <div class="gl-flex gl-items-center">
          {{ label }}
          <disabled-by-policy-popover
            v-if="isProtectedByAnyPolicyType"
            :is-protected-by-policy="isProtectedByPolicy"
          />
          <group-inheritance-popover
            v-else-if="isGroupLevel"
            :has-group-permissions="canAdminGroupProtectedBranches"
            :group-settings-repository-path="groupSettingsRepositoryPath"
          />
        </div>
      </template>
      <template v-if="hasDescription" #description>
        <gl-sprintf :message="description">
          <template #link="{ content }">
            <gl-link :href="descriptionLink">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-toggle>
  </div>
  <div v-else class="gl-mb-5">
    <div class="gl-flex gl-items-center">
      <gl-icon :data-testid="iconDataTestId" :size="14" :name="iconName" :variant="iconVariant" />
      <strong class="gl-ml-2">{{ iconTitle }}</strong>
    </div>
    <gl-sprintf v-if="hasDescription" :message="description" data-testid="protection-description">
      <template #link="{ content }">
        <gl-link :href="descriptionLink">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

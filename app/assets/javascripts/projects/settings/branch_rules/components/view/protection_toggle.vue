<script>
import { GlToggle, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
} from './constants';

export default {
  components: {
    GlToggle,
    GlIcon,
    GlSprintf,
    GlLink,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    canAdminProtectedBranches: { default: false },
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
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    iconName() {
      return this.isProtected ? REQUIRED_ICON : NOT_REQUIRED_ICON;
    },
    iconClass() {
      return this.isProtected ? REQUIRED_ICON_CLASS : NOT_REQUIRED_ICON_CLASS;
    },
    iconDataTestId() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return this.dataTestIdPrefix ? `${this.dataTestIdPrefix}-icon` : '';
    },
    hasDescription() {
      if (!this.glFeatures.editBranchRules) {
        return Boolean(this.description);
      }

      return this.isProtected ? Boolean(this.description) : false;
    },
    canEditProtectionToggles() {
      return this.canAdminProtectedBranches && this.glFeatures.editBranchRules;
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
      class="gl-mb-5"
      @change="$emit('toggle', $event)"
    >
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
      <gl-icon :data-testid="iconDataTestId" :size="14" :name="iconName" :class="iconClass" />
      <strong class="gl-ml-2">{{ iconTitle }}</strong>
    </div>
    <gl-sprintf v-if="hasDescription" :message="description" data-testid="protection-description">
      <template #link="{ content }">
        <gl-link :href="descriptionLink">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>

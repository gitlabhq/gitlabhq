<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

export const i18n = {
  defaultLabel: s__('BranchRules|default'),
  protectedLabel: s__('BranchRules|protected'),
  detailsButtonLabel: s__('BranchRules|Details'),
};

export default {
  name: 'BranchRule',
  i18n,
  components: {
    GlBadge,
    GlButton,
  },
  inject: {
    branchRulesPath: {
      default: '',
    },
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    isDefault: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProtected: {
      type: Boolean,
      required: false,
      default: false,
    },
    approvalDetails: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    hasApprovalDetails() {
      return this.approvalDetails && this.approvalDetails.length;
    },
    detailsPath() {
      return `${this.branchRulesPath}?branch=${this.name}`;
    },
  },
};
</script>

<template>
  <div class="gl-border-b gl-pt-5 gl-pb-5 gl-display-flex gl-justify-content-space-between">
    <div>
      <strong class="gl-font-monospace">{{ name }}</strong>

      <gl-badge v-if="isDefault" variant="info" size="sm" class="gl-ml-2">{{
        $options.i18n.defaultLabel
      }}</gl-badge>

      <gl-badge v-if="isProtected" variant="success" size="sm" class="gl-ml-2">{{
        $options.i18n.protectedLabel
      }}</gl-badge>

      <ul v-if="hasApprovalDetails" class="gl-pl-6 gl-mt-2 gl-mb-0 gl-text-gray-500">
        <li v-for="(detail, index) in approvalDetails" :key="index">{{ detail }}</li>
      </ul>
    </div>
    <gl-button :href="detailsPath"> {{ $options.i18n.detailsButtonLabel }}</gl-button>
  </div>
</template>

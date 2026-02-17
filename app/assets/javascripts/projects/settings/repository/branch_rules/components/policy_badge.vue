<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    policyLabel: s__('BranchRules|Enforced by policy'),
    policyLabelWarnModel: s__('BranchRules|Policy warn mode'),
  },
  name: 'PolicyBadge',
  components: {
    GlBadge,
  },
  inject: {
    securityPoliciesPath: {
      default: '',
    },
  },
  props: {
    isProtectedByPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    text() {
      return this.isProtectedByPolicy
        ? this.$options.i18n.policyLabel
        : this.$options.i18n.policyLabelWarnModel;
    },
    variant() {
      return this.isProtectedByPolicy ? 'info' : 'neutral';
    },
  },
};
</script>

<template>
  <gl-badge :variant="variant" icon="shield">
    {{ text }}
  </gl-badge>
</template>

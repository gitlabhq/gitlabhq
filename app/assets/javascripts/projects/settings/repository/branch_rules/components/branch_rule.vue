<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { s__, sprintf, n__ } from '~/locale';

export const i18n = {
  defaultLabel: s__('BranchRules|default'),
  detailsButtonLabel: s__('BranchRules|Details'),
  allowForcePush: s__('BranchRules|Allowed to force push'),
  codeOwnerApprovalRequired: s__('BranchRules|Requires CODEOWNERS approval'),
  statusChecks: s__('BranchRules|%{total} status %{subject}'),
  approvalRules: s__('BranchRules|%{total} approval %{subject}'),
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
    branchProtection: {
      type: Object,
      required: false,
      default: () => {},
    },
    statusChecksTotal: {
      type: Number,
      required: false,
      default: 0,
    },
    approvalRulesTotal: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    hasApprovalDetails() {
      return this.approvalDetails.length;
    },
    detailsPath() {
      return `${this.branchRulesPath}?branch=${this.name}`;
    },
    statusChecksText() {
      return sprintf(this.$options.i18n.statusChecks, {
        total: this.statusChecksTotal,
        subject: n__('check', 'checks', this.statusChecksTotal),
      });
    },
    approvalRulesText() {
      return sprintf(this.$options.i18n.approvalRules, {
        total: this.approvalRulesTotal,
        subject: n__('rule', 'rules', this.approvalRulesTotal),
      });
    },
    approvalDetails() {
      const approvalDetails = [];
      if (this.branchProtection.allowForcePush) {
        approvalDetails.push(this.$options.i18n.allowForcePush);
      }
      if (this.branchProtection.codeOwnerApprovalRequired) {
        approvalDetails.push(this.$options.i18n.codeOwnerApprovalRequired);
      }
      if (this.statusChecksTotal) {
        approvalDetails.push(this.statusChecksText);
      }
      if (this.approvalRulesTotal) {
        approvalDetails.push(this.approvalRulesText);
      }
      return approvalDetails;
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

      <ul v-if="hasApprovalDetails" class="gl-pl-6 gl-mt-2 gl-mb-0 gl-text-gray-500">
        <li v-for="(detail, index) in approvalDetails" :key="index">{{ detail }}</li>
      </ul>
    </div>
    <gl-button class="gl-align-self-start" :href="detailsPath">
      {{ $options.i18n.detailsButtonLabel }}</gl-button
    >
  </div>
</template>

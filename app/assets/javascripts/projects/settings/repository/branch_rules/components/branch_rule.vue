<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { s__, sprintf, n__ } from '~/locale';
import { accessLevelsConfig } from '~/projects/settings/branch_rules/components/view/constants';
import { getAccessLevels } from '../../../utils';

export default {
  name: 'BranchRule',
  accessLevelsConfig,
  i18n: {
    defaultLabel: s__('BranchRules|default'),
    detailsButtonLabel: s__('BranchRules|View details'),
    allowForcePush: s__('BranchRules|Allowed to force push'),
    codeOwnerApprovalRequired: s__('BranchRules|Requires CODEOWNERS approval'),
    statusChecks: s__('BranchRules|%{total} status %{subject}'),
    approvalRules: s__('BranchRules|%{total} approval %{subject}'),
    matchingBranches: s__('BranchRules|%{total} matching %{subject}'),
    pushAccessLevels: s__('BranchRules|Allowed to push and merge'),
    mergeAccessLevels: s__('BranchRules|Allowed to merge'),
    squashSetting: s__('BranchRules|Squash commits: %{setting}'),
  },
  components: {
    GlBadge,
    GlButton,
    ProtectedBadge,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    branchRulesPath: {
      default: '',
    },
    showCodeOwners: { default: false },
    showStatusChecks: { default: false },
    showApprovers: { default: false },
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
    matchingBranchesCount: {
      type: Number,
      required: false,
      default: 0,
    },
    squashOption: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  computed: {
    isWildcard() {
      return this.name.includes('*');
    },
    isProtected() {
      return Boolean(this.branchProtection);
    },
    hasApprovalDetails() {
      return this.approvalDetails.length;
    },
    detailsPath() {
      return `${this.branchRulesPath}?branch=${encodeURIComponent(this.name)}`;
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
    matchingBranchesText() {
      return sprintf(this.$options.i18n.matchingBranches, {
        total: this.matchingBranchesCount,
        subject: n__('branch', 'branches', this.matchingBranchesCount),
      });
    },
    squashSettingText() {
      return sprintf(this.$options.i18n.squashSetting, {
        setting: this.squashOption?.option,
      });
    },
    mergeAccessLevels() {
      const { mergeAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(mergeAccessLevels);
    },
    pushAccessLevels() {
      const { pushAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(pushAccessLevels);
    },
    pushAccessLevelsText() {
      return this.getAccessLevelsText(this.$options.i18n.pushAccessLevels, this.pushAccessLevels);
    },
    mergeAccessLevelsText() {
      return this.getAccessLevelsText(this.$options.i18n.mergeAccessLevels, this.mergeAccessLevels);
    },
    approvalDetails() {
      const approvalDetails = [];
      if (this.isWildcard || this.matchingBranchesCount > 1) {
        approvalDetails.push(this.matchingBranchesText);
      }
      if (this.branchProtection?.allowForcePush) {
        approvalDetails.push(this.$options.i18n.allowForcePush);
      }
      if (this.showCodeOwners && this.branchProtection?.codeOwnerApprovalRequired) {
        approvalDetails.push(this.$options.i18n.codeOwnerApprovalRequired);
      }
      if (this.showStatusChecks && this.statusChecksTotal) {
        approvalDetails.push(this.statusChecksText);
      }
      if (this.showApprovers && this.approvalRulesTotal) {
        approvalDetails.push(this.approvalRulesText);
      }
      if (this.mergeAccessLevels.total > 0) {
        approvalDetails.push(this.mergeAccessLevelsText);
      }
      if (this.pushAccessLevels.total > 0) {
        approvalDetails.push(this.pushAccessLevelsText);
      }
      if (this.glFeatures.branchRuleSquashSettings && this.squashOption) {
        approvalDetails.push(this.squashSettingText);
      }
      return approvalDetails;
    },
  },
  methods: {
    getAccessLevels,
    getAccessLevelsText(beginString = '', accessLevels) {
      const textParts = [];
      if (accessLevels.roles.length) {
        const roles = accessLevels.roles.map(
          (roleInteger) => accessLevelsConfig[roleInteger].accessLevelLabel,
        );
        textParts.push(roles.join(', '));
      }
      if (accessLevels.groups.length) {
        textParts.push(n__('1 group', '%d groups', accessLevels.groups.length));
      }
      if (accessLevels.users.length) {
        textParts.push(n__('1 user', '%d users', accessLevels.users.length));
      }
      return `${beginString}: ${textParts.join(', ')}`;
    },
  },
};
</script>

<template>
  <li>
    <div
      class="gl-flex gl-justify-between"
      data-testid="branch-content"
      :data-qa-branch-name="name"
    >
      <div>
        <strong class="gl-font-monospace">{{ name }}</strong>

        <gl-badge v-if="isDefault" variant="info" class="gl-ml-2">{{
          $options.i18n.defaultLabel
        }}</gl-badge>

        <protected-badge v-if="isProtected" />

        <ul v-if="hasApprovalDetails" class="gl-mb-0 gl-mt-2 gl-pl-6 gl-text-subtle">
          <li v-for="(detail, index) in approvalDetails" :key="index">{{ detail }}</li>
        </ul>
      </div>
      <gl-button
        class="gl-self-start"
        category="tertiary"
        size="small"
        data-testid="details-button"
        :href="detailsPath"
      >
        {{ $options.i18n.detailsButtonLabel }}</gl-button
      >
    </div>
  </li>
</template>

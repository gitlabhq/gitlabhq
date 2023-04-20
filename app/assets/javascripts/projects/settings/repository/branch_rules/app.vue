<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import BranchRule from './components/branch_rule.vue';
import { I18N, PROTECTED_BRANCHES_ANCHOR, BRANCH_PROTECTION_MODAL_ID } from './constants';

export default {
  name: 'BranchRules',
  i18n: I18N,
  components: {
    BranchRule,
    GlButton,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  apollo: {
    branchRules: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.branchRules?.nodes || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.queryError });
      },
    },
  },
  inject: {
    projectPath: { default: '' },
  },
  data() {
    return {
      branchRules: [],
    };
  },
  methods: {
    showProtectedBranches() {
      // Protected branches section is on the same page as the branch rules section.
      expandSection(this.$options.protectedBranchesAnchor);
      scrollToElement(this.$options.protectedBranchesAnchor);
    },
  },
  modalId: BRANCH_PROTECTION_MODAL_ID,
  protectedBranchesAnchor: PROTECTED_BRANCHES_ANCHOR,
};
</script>

<template>
  <div class="settings-content gl-mb-0">
    <branch-rule
      v-for="(rule, index) in branchRules"
      :key="`${rule.name}-${index}`"
      :name="rule.name"
      :is-default="rule.isDefault"
      :branch-protection="rule.branchProtection"
      :status-checks-total="rule.externalStatusChecks ? rule.externalStatusChecks.nodes.length : 0"
      :approval-rules-total="rule.approvalRules ? rule.approvalRules.nodes.length : 0"
      :matching-branches-count="rule.matchingBranchesCount"
    />

    <div v-if="!branchRules.length" data-testid="empty">{{ $options.i18n.emptyState }}</div>

    <gl-button
      v-gl-modal="$options.modalId"
      class="gl-mt-5"
      data-qa-selector="add_branch_rule_button"
      category="secondary"
      variant="info"
      >{{ $options.i18n.addBranchRule }}</gl-button
    >

    <gl-modal
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="$options.i18n.addBranchRule"
      :ok-title="$options.i18n.createProtectedBranch"
      @ok="showProtectedBranches"
    >
      <p>{{ $options.i18n.branchRuleModalDescription }}</p>
      <p>{{ $options.i18n.branchRuleModalContent }}</p>
    </gl-modal>
  </div>
</template>

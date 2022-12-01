<script>
import { s__ } from '~/locale';
import { createAlert } from '~/flash';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import BranchRule from './components/branch_rule.vue';

export const i18n = {
  queryError: s__(
    'ProtectedBranch|An error occurred while loading branch rules. Please try again.',
  ),
  emptyState: s__(
    'ProtectedBranch|Protected branches, merge request approvals, and status checks will appear here once configured.',
  ),
};

export default {
  name: 'BranchRules',
  i18n,
  components: {
    BranchRule,
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
    projectPath: {
      default: '',
    },
  },
  data() {
    return {
      branchRules: [],
    };
  },
};
</script>

<template>
  <div class="settings-content">
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

    <span v-if="!branchRules.length" data-testid="empty">{{ $options.i18n.emptyState }}</span>
  </div>
</template>

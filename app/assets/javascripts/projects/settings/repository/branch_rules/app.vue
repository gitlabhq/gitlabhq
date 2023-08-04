<script>
import { GlButton, GlModal, GlModalDirective, GlCard, GlIcon } from '@gitlab/ui';
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
    GlCard,
    GlIcon,
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
  <gl-card
    class="gl-new-card gl-overflow-hidden"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper" data-testid="title">
        <h3 class="gl-new-card-title">
          {{ __('Branch Rules') }}
        </h3>
        <div class="gl-new-card-count">
          <gl-icon name="branch" class="gl-mr-2" />
          {{ branchRules.length }}
        </div>
      </div>
      <gl-button
        v-gl-modal="$options.modalId"
        size="small"
        class="gl-ml-3"
        data-qa-selector="add_branch_rule_button"
        >{{ $options.i18n.addBranchRule }}</gl-button
      >
    </template>
    <ul class="content-list">
      <branch-rule
        v-for="(rule, index) in branchRules"
        :key="`${rule.name}-${index}`"
        :name="rule.name"
        :is-default="rule.isDefault"
        :branch-protection="rule.branchProtection"
        :status-checks-total="
          rule.externalStatusChecks ? rule.externalStatusChecks.nodes.length : 0
        "
        :approval-rules-total="rule.approvalRules ? rule.approvalRules.nodes.length : 0"
        :matching-branches-count="rule.matchingBranchesCount"
        class="gl-px-5! gl-py-4!"
      />
      <div v-if="!branchRules.length" class="gl-new-card-empty gl-px-5 gl-py-4" data-testid="empty">
        {{ $options.i18n.emptyState }}
      </div>
    </ul>
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
  </gl-card>
</template>

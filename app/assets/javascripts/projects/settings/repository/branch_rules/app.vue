<script>
import { GlButton, GlModal, GlModalDirective, GlDisclosureDropdown } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  BRANCH_RULE_DETAILS_LABEL,
  PROTECTED_BRANCH,
} from '~/projects/settings/branch_rules/tracking/constants';
import BranchRuleModal from '../../components/branch_rule_modal.vue';
import createBranchRuleMutation from './graphql/mutations/create_branch_rule.mutation.graphql';
import BranchRule from './components/branch_rule.vue';
import { I18N, PROTECTED_BRANCHES_ANCHOR, BRANCH_PROTECTION_MODAL_ID } from './constants';

export default {
  name: 'BranchRules',
  i18n: I18N,
  components: {
    BranchRule,
    BranchRuleModal,
    GlButton,
    GlModal,
    GlDisclosureDropdown,
    CrudComponent,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
    branchRulesPath: { default: '' },
    showStatusChecks: { default: false },
    showApprovers: { default: false },
  },
  data() {
    return {
      branchRules: [],
    };
  },
  computed: {
    getAddRuleItems() {
      const items = [
        { text: this.$options.i18n.branchName, action: () => this.openCreateRuleModal() },
      ];

      if (this.showApprovers || this.showStatusChecks) {
        [this.$options.i18n.allBranches, this.$options.i18n.allProtectedBranches].forEach(
          (branch) => {
            if (!this.hasPredefinedBranchRule(branch)) {
              items.push(this.createPredefinedBrachRulesItem(branch));
            }
          },
        );
      }

      return items;
    },
    createRuleItems() {
      return this.isWildcardAvailable ? [this.wildcardItem] : this.filteredOpenBranches;
    },
    filteredOpenBranches() {
      const openBranches = window.gon.open_branches.map((item) => ({
        text: item.text,
        value: item.text,
      }));
      return openBranches.filter((item) => item.text.includes(this.searchQuery));
    },
    wildcardItem() {
      return { text: this.$options.i18n.createWildcard, value: this.searchQuery };
    },
    isWildcardAvailable() {
      return this.searchQuery.includes('*');
    },
    createRuleText() {
      return this.branchRuleName || this.$options.i18n.branchNamePlaceholder;
    },
    primaryProps() {
      return {
        text: this.$options.i18n.createProtectedBranch,
        attributes: {
          variant: 'confirm',
          disabled: !this.branchRuleName,
        },
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.createBranchRule,
      };
    },
  },
  methods: {
    createPredefinedBrachRulesItem(branchRuleName) {
      return {
        text: branchRuleName,
        action: () => this.redirectToEdit(branchRuleName),
      };
    },
    redirectToEdit(branch) {
      visitUrl(`${this.branchRulesPath}?branch=${encodeURIComponent(branch)}`);
    },
    hasPredefinedBranchRule(branchName) {
      return Boolean(this.branchRules.filter((rule) => rule.name === branchName).length);
    },
    showProtectedBranches() {
      // Protected branches section is on the same page as the branch rules section.
      expandSection(this.$options.protectedBranchesAnchor);
      scrollToElement(this.$options.protectedBranchesAnchor);
    },
    openCreateRuleModal() {
      this.$refs[this.$options.modalId].show();
    },
    addBranchRule({ name }) {
      this.$apollo
        .mutate({
          mutation: createBranchRuleMutation,
          variables: {
            projectPath: this.projectPath,
            name,
          },
        })
        .then(() => {
          InternalEvents.trackEvent(PROTECTED_BRANCH, {
            label: BRANCH_RULE_DETAILS_LABEL,
          });
          visitUrl(this.getBranchRuleEditPath(name));
        })
        .catch(() => {
          createAlert({ message: this.$options.i18n.createBranchRuleError });
        });
    },
    getBranchRuleEditPath(name) {
      return `${this.branchRulesPath}?branch=${encodeURIComponent(name)}`;
    },
  },
  modalId: BRANCH_PROTECTION_MODAL_ID,
  protectedBranchesAnchor: PROTECTED_BRANCHES_ANCHOR,
};
</script>

<template>
  <crud-component
    :title="__('Branch rules')"
    icon="branch"
    :count="branchRules.length"
    class="gl-mb-5"
    :is-loading="$apollo.queries.branchRules.loading"
  >
    <template #actions>
      <gl-disclosure-dropdown
        v-if="glFeatures.editBranchRules"
        :toggle-text="$options.i18n.addBranchRule"
        :items="getAddRuleItems"
        size="small"
      />
      <gl-button v-else v-gl-modal="$options.modalId" size="small" class="gl-ml-3"
        >{{ $options.i18n.addBranchRule }}
      </gl-button>
    </template>

    <template v-if="!branchRules.length" #empty>
      {{ $options.i18n.emptyState }}
    </template>

    <template #default>
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
          :squash-option="rule.squashOption"
        />
      </ul>

      <branch-rule-modal
        v-if="glFeatures.editBranchRules"
        :id="$options.modalId"
        :ref="$options.modalId"
        :title="$options.i18n.createBranchRule"
        :action-primary-text="$options.i18n.createProtectedBranch"
        @primary="addBranchRule({ name: $event })"
      />
      <gl-modal
        v-else
        :ref="$options.modalId"
        :modal-id="$options.modalId"
        :title="$options.i18n.addBranchRule"
        :ok-title="$options.i18n.createProtectedBranch"
        @ok="showProtectedBranches"
      >
        <p>{{ $options.i18n.branchRuleModalDescription }}</p>
        <p>{{ $options.i18n.branchRuleModalContent }}</p>
      </gl-modal>
    </template>
  </crud-component>
</template>

<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import {
  GlSprintf,
  GlLink,
  GlLoadingIcon,
  GlIcon,
  GlCard,
  GlButton,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { sprintf, n__, s__ } from '~/locale';
import {
  getParameterByName,
  mergeUrlParams,
  visitUrl,
  setUrlParams,
} from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import deleteBranchRuleMutation from '../../mutations/branch_rule_delete.mutation.graphql';
import editBranchRuleMutation from '../../mutations/edit_branch_rule.mutation.graphql';
import { getAccessLevels } from '../../../utils';
import BranchRuleModal from '../../../components/branch_rule_modal.vue';
import Protection from './protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  BRANCH_PARAM_NAME,
  PROTECTED_BRANCHES_HELP_PATH,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
  DELETE_RULE_MODAL_ID,
  EDIT_RULE_MODAL_ID,
} from './constants';

const protectedBranchesHelpDocLink = helpPagePath(PROTECTED_BRANCHES_HELP_PATH);

export default {
  name: 'RuleView',
  i18n: I18N,
  deleteModalId: DELETE_RULE_MODAL_ID,
  protectedBranchesHelpDocLink,
  directives: {
    GlModal: GlModalDirective,
  },
  editModalId: EDIT_RULE_MODAL_ID,
  components: {
    Protection,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    GlIcon,
    GlCard,
    GlModal,
    GlButton,
    BranchRuleModal,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    projectPath: {
      default: '',
    },
    protectedBranchesPath: {
      default: '',
    },
    branchRulesPath: {
      default: '',
    },
    branchesPath: {
      default: '',
    },
    showStatusChecks: { default: false },
    showApprovers: { default: false },
    showCodeOwners: { default: false },
  },
  apollo: {
    project: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project: { branchRules } }) {
        const branchRule = branchRules.nodes.find((rule) => rule.name === this.branch);
        this.branchRule = branchRule;
        this.branchProtection = branchRule?.branchProtection;
        this.statusChecks = branchRule?.externalStatusChecks?.nodes || [];
        this.matchingBranchesCount = branchRule?.matchingBranchesCount;

        if (!this.showApprovers) return;
        // The approval rules app uses a separate endpoint to fetch the list of approval rules.
        // In future, we will update the GraphQL request to include the approval rules data.
        // Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/452330
        const approvalRules = branchRule?.approvalRules?.nodes.map((rule) => rule.name) || [];
        this.setRulesFilter(approvalRules);
        this.fetchRules();
      },
      error(error) {
        createAlert({ message: error });
      },
    },
  },
  data() {
    return {
      branch: getParameterByName(BRANCH_PARAM_NAME),
      branchProtection: {},
      statusChecks: [],
      branchRule: {},
      matchingBranchesCount: null,
    };
  },
  computed: {
    forcePushAttributes() {
      const { allowForcePush } = this.branchProtection || {};
      const icon = allowForcePush ? REQUIRED_ICON : NOT_REQUIRED_ICON;
      const iconClass = allowForcePush ? REQUIRED_ICON_CLASS : NOT_REQUIRED_ICON_CLASS;
      const title = allowForcePush
        ? this.$options.i18n.allowForcePushTitle
        : this.$options.i18n.doesNotAllowForcePushTitle;

      return { icon, iconClass, title };
    },
    codeOwnersApprovalAttributes() {
      const { codeOwnerApprovalRequired } = this.branchProtection || {};
      const icon = codeOwnerApprovalRequired ? REQUIRED_ICON : NOT_REQUIRED_ICON;
      const iconClass = codeOwnerApprovalRequired ? REQUIRED_ICON_CLASS : NOT_REQUIRED_ICON_CLASS;
      const title = codeOwnerApprovalRequired
        ? this.$options.i18n.requiresCodeOwnerApprovalTitle
        : this.$options.i18n.doesNotRequireCodeOwnerApprovalTitle;
      const description = codeOwnerApprovalRequired
        ? this.$options.i18n.requiresCodeOwnerApprovalDescription
        : this.$options.i18n.doesNotRequireCodeOwnerApprovalDescription;

      return { icon, iconClass, title, description };
    },
    mergeAccessLevels() {
      const { mergeAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(mergeAccessLevels);
    },
    pushAccessLevels() {
      const { pushAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(pushAccessLevels);
    },
    allowedToMergeHeader() {
      return sprintf(this.$options.i18n.allowedToMergeHeader, {
        total: this.mergeAccessLevels?.total || 0,
      });
    },
    allowedToPushHeader() {
      return sprintf(this.$options.i18n.allowedToPushHeader, {
        total: this.pushAccessLevels?.total || 0,
      });
    },
    allBranches() {
      return this.branch === ALL_BRANCHES_WILDCARD;
    },
    matchingBranchesLinkHref() {
      return mergeUrlParams({ state: 'all', search: `^${this.branch}$` }, this.branchesPath);
    },
    matchingBranchesLinkTitle() {
      const total = this.matchingBranchesCount;
      const subject = n__('branch', 'branches', total);
      return sprintf(this.$options.i18n.matchingBranchesLinkTitle, { total, subject });
    },
    // needed to override EE component
    statusChecksHeader() {
      return '';
    },
  },
  methods: {
    ...mapActions(['setRulesFilter', 'fetchRules']),
    getAccessLevels,
    deleteBranchRule() {
      this.$apollo
        .mutate({
          mutation: deleteBranchRuleMutation,
          variables: {
            input: {
              id: this.branchRule.id,
            },
          },
        })
        .then(
          // eslint-disable-next-line consistent-return
          ({ data: { branchRuleDelete } = {} } = {}) => {
            const [error] = branchRuleDelete.errors;
            if (error) {
              return createAlert({
                message: error.message,
                captureError: true,
              });
            }
            visitUrl(this.branchRulesPath);
          },
        )
        .catch(() => {
          return createAlert({
            message: s__('BranchRules|Something went wrong while deleting branch rule.'),
            captureError: true,
          });
        });
    },
    editBranchRule({ name }) {
      this.$apollo
        .mutate({
          mutation: editBranchRuleMutation,
          variables: {
            id: this.branchRule.id,
            name,
          },
        })
        .then(visitUrl(setUrlParams({ branch: name })))
        .catch(() => {
          createAlert({ message: this.$options.i18n.updateBranchRuleError });
        });
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h1 class="h3 gl-mb-5">{{ $options.i18n.pageTitle }}</h1>
      <gl-button
        v-if="glFeatures.editBranchRules && branchRule"
        v-gl-modal="$options.deleteModalId"
        data-testid="delete-rule-button"
        category="secondary"
        variant="danger"
        :disabled="$apollo.loading"
        >{{ $options.i18n.deleteRule }}
      </gl-button>
    </div>
    <gl-loading-icon v-if="$apollo.loading" size="lg" />
    <div v-else-if="!branchRule">{{ $options.i18n.noData }}</div>
    <div v-else>
      <gl-card
        class="gl-new-card"
        header-class="gl-new-card-header"
        body-class="gl-new-card-body gl-p-5"
      >
        <template #header>
          <strong>{{ $options.i18n.ruleTarget }}</strong>
          <gl-button
            v-if="glFeatures.addBranchRule || glFeatures.editBranchRules"
            v-gl-modal="$options.editModalId"
            data-testid="edit-rule-button"
            size="small"
            >{{ $options.i18n.edit }}</gl-button
          >
        </template>
        <div v-if="allBranches" class="gl-mt-2" data-testid="all-branches">
          {{ $options.i18n.allBranches }}
        </div>
        <code v-else class="gl-bg-none p-0 gl-font-base" data-testid="branch">{{ branch }}</code>
        <p v-if="matchingBranchesCount" class="gl-mt-3 gl-mb-0">
          <gl-link :href="matchingBranchesLinkHref">{{ matchingBranchesLinkTitle }}</gl-link>
        </p>
      </gl-card>

      <h2 class="h4 gl-mb-1 gl-mt-5">{{ $options.i18n.protectBranchTitle }}</h2>
      <gl-sprintf :message="$options.i18n.protectBranchDescription">
        <template #link="{ content }">
          <gl-link :href="$options.protectedBranchesHelpDocLink">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>

      <!-- Allowed to push -->
      <protection
        class="gl-mt-3"
        :header="allowedToPushHeader"
        :header-link-title="$options.i18n.manageProtectionsLinkTitle"
        :header-link-href="protectedBranchesPath"
        :roles="pushAccessLevels.roles"
        :users="pushAccessLevels.users"
        :groups="pushAccessLevels.groups"
        data-testid="allowed-to-push-content"
      />

      <!-- Allowed to merge -->
      <protection
        :header="allowedToMergeHeader"
        :header-link-title="$options.i18n.manageProtectionsLinkTitle"
        :header-link-href="protectedBranchesPath"
        :roles="mergeAccessLevels.roles"
        :users="mergeAccessLevels.users"
        :groups="mergeAccessLevels.groups"
        data-testid="allowed-to-merge-content"
      />

      <!-- Force push -->
      <div class="gl-display-flex gl-align-items-center">
        <gl-icon
          :size="14"
          data-testid="force-push-icon"
          :name="forcePushAttributes.icon"
          :class="forcePushAttributes.iconClass"
        />
        <strong class="gl-ml-2">{{ forcePushAttributes.title }}</strong>
      </div>

      <div class="gl-text-gray-400 gl-mb-2">{{ $options.i18n.forcePushDescription }}</div>

      <!-- EE start -->
      <!-- Code Owners -->
      <div v-if="showCodeOwners">
        <div class="gl-display-flex gl-align-items-center">
          <gl-icon
            data-testid="code-owners-icon"
            :size="14"
            :name="codeOwnersApprovalAttributes.icon"
            :class="codeOwnersApprovalAttributes.iconClass"
          />
          <strong class="gl-ml-2">{{ codeOwnersApprovalAttributes.title }}</strong>
        </div>

        <div class="gl-text-gray-400">{{ codeOwnersApprovalAttributes.description }}</div>
      </div>

      <!-- Approvals -->
      <template v-if="showApprovers">
        <h2 class="h4 gl-mb-1 gl-mt-5">{{ $options.i18n.approvalsTitle }}</h2>
        <gl-sprintf :message="$options.i18n.approvalsDescription">
          <template #link="{ content }">
            <gl-link :href="$options.approvalsHelpDocLink">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>

        <approval-rules-app
          :is-mr-edit="false"
          :is-branch-rules-edit="true"
          @submitted="$apollo.queries.project.refetch()"
        >
          <template #rules>
            <project-rules :is-branch-rules-edit="true" />
          </template>
        </approval-rules-app>
      </template>

      <!-- Status checks -->
      <template v-if="showStatusChecks">
        <h2 class="h4 gl-mb-1 gl-mt-5">{{ $options.i18n.statusChecksTitle }}</h2>
        <gl-sprintf :message="$options.i18n.statusChecksDescription">
          <template #link="{ content }">
            <gl-link :href="$options.statusChecksHelpDocLink">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>

        <protection
          class="gl-mt-3"
          :header="statusChecksHeader"
          :header-link-title="$options.i18n.statusChecksLinkTitle"
          :header-link-href="statusChecksPath"
          :status-checks="statusChecks"
        />
      </template>
      <!-- EE end -->
      <gl-modal
        v-if="glFeatures.editBranchRules"
        :ref="$options.deleteModalId"
        :modal-id="$options.deleteModalId"
        :title="$options.i18n.deleteRuleModalTitle"
        :ok-title="$options.i18n.deleteRuleModalDeleteText"
        ok-variant="danger"
        @ok="deleteBranchRule"
      >
        <p>{{ $options.i18n.deleteRuleModalText }}</p>
      </gl-modal>

      <branch-rule-modal
        v-if="glFeatures.editBranchRules"
        :id="$options.editModalId"
        :ref="$options.editModalId"
        :title="$options.i18n.updateTargetRule"
        :action-primary-text="$options.i18n.update"
        @primary="editBranchRule({ name: $event })"
      />
    </div>
  </div>
</template>

<script>
import { GlSprintf, GlLink, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { sprintf, n__ } from '~/locale';
import { getParameterByName, mergeUrlParams } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { getAccessLevels } from '../../../utils';
import Protection from './protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  BRANCH_PARAM_NAME,
  WILDCARDS_HELP_PATH,
  PROTECTED_BRANCHES_HELP_PATH,
  REQUIRED_ICON,
  NOT_REQUIRED_ICON,
  REQUIRED_ICON_CLASS,
  NOT_REQUIRED_ICON_CLASS,
} from './constants';

const wildcardsHelpDocLink = helpPagePath(WILDCARDS_HELP_PATH);
const protectedBranchesHelpDocLink = helpPagePath(PROTECTED_BRANCHES_HELP_PATH);

export default {
  name: 'RuleView',
  i18n: I18N,
  wildcardsHelpDocLink,
  protectedBranchesHelpDocLink,
  components: { Protection, GlSprintf, GlLink, GlLoadingIcon, GlIcon },
  inject: {
    projectPath: {
      default: '',
    },
    protectedBranchesPath: {
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
        this.approvalRules = branchRule?.approvalRules?.nodes || [];
        this.statusChecks = branchRule?.externalStatusChecks?.nodes || [];
        this.matchingBranchesCount = branchRule?.matchingBranchesCount;
      },
    },
  },
  data() {
    return {
      branch: getParameterByName(BRANCH_PARAM_NAME),
      branchProtection: {},
      approvalRules: {},
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
    allBranchesLabel() {
      return this.$options.i18n.allBranches;
    },
    branchTitle() {
      return this.allBranches
        ? this.$options.i18n.targetBranch
        : this.$options.i18n.branchNameOrPattern;
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
    // needed to override EE component
    approvalsHeader() {
      return '';
    },
  },
  methods: {
    getAccessLevels,
  },
};
</script>

<template>
  <gl-loading-icon v-if="$apollo.loading" />
  <div v-else-if="!branchRule">{{ $options.i18n.noData }}</div>
  <div v-else>
    <strong data-testid="branch-title">{{ branchTitle }}</strong>
    <p v-if="!allBranches" class="gl-mb-3 gl-text-gray-400">
      <gl-sprintf :message="$options.i18n.wildcardsHelpText">
        <template #link="{ content }">
          <gl-link :href="$options.wildcardsHelpDocLink">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>

    <div v-if="allBranches" class="gl-mt-2" data-testid="branch">
      {{ allBranchesLabel }}
    </div>
    <code v-else class="gl-mt-2" data-testid="branch">{{ branch }}</code>

    <p v-if="matchingBranchesCount" class="gl-mt-3">
      <gl-link :href="matchingBranchesLinkHref">{{ matchingBranchesLinkTitle }}</gl-link>
    </p>

    <h4 class="gl-mb-1 gl-mt-5">{{ $options.i18n.protectBranchTitle }}</h4>
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
      data-qa-selector="allowed_to_push_content"
    />

    <!-- Allowed to merge -->
    <protection
      :header="allowedToMergeHeader"
      :header-link-title="$options.i18n.manageProtectionsLinkTitle"
      :header-link-href="protectedBranchesPath"
      :roles="mergeAccessLevels.roles"
      :users="mergeAccessLevels.users"
      :groups="mergeAccessLevels.groups"
      data-qa-selector="allowed_to_merge_content"
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
      <h4 class="gl-mb-1 gl-mt-5">{{ $options.i18n.approvalsTitle }}</h4>
      <gl-sprintf :message="$options.i18n.approvalsDescription">
        <template #link="{ content }">
          <gl-link :href="$options.approvalsHelpDocLink">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>

      <protection
        class="gl-mt-3"
        :header="approvalsHeader"
        :header-link-title="$options.i18n.manageApprovalsLinkTitle"
        :header-link-href="approvalRulesPath"
        :approvals="approvalRules"
      />
    </template>

    <!-- Status checks -->
    <template v-if="showStatusChecks">
      <h4 class="gl-mb-1 gl-mt-5">{{ $options.i18n.statusChecksTitle }}</h4>
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
  </div>
</template>

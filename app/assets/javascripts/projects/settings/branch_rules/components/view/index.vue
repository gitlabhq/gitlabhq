<script>
import { GlSprintf, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { sprintf, n__ } from '~/locale';
import { getParameterByName, mergeUrlParams } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchRulesQuery from '../../queries/branch_rules_details.query.graphql';
import { getAccessLevels } from '../../../utils';
import Protection from './protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  BRANCH_PARAM_NAME,
  WILDCARDS_HELP_PATH,
  PROTECTED_BRANCHES_HELP_PATH,
  APPROVALS_HELP_PATH,
  STATUS_CHECKS_HELP_PATH,
} from './constants';

const wildcardsHelpDocLink = helpPagePath(WILDCARDS_HELP_PATH);
const protectedBranchesHelpDocLink = helpPagePath(PROTECTED_BRANCHES_HELP_PATH);
const approvalsHelpDocLink = helpPagePath(APPROVALS_HELP_PATH);
const statusChecksHelpDocLink = helpPagePath(STATUS_CHECKS_HELP_PATH);

export default {
  name: 'RuleView',
  i18n: I18N,
  wildcardsHelpDocLink,
  protectedBranchesHelpDocLink,
  approvalsHelpDocLink,
  statusChecksHelpDocLink,
  components: { Protection, GlSprintf, GlLink, GlLoadingIcon },
  inject: {
    projectPath: {
      default: '',
    },
    protectedBranchesPath: {
      default: '',
    },
    approvalRulesPath: {
      default: '',
    },
    statusChecksPath: {
      default: '',
    },
    branchesPath: {
      default: '',
    },
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
        this.approvalRules = branchRule?.approvalRules;
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
    forcePushDescription() {
      return this.branchProtection?.allowForcePush
        ? this.$options.i18n.allowForcePushDescription
        : this.$options.i18n.disallowForcePushDescription;
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
    approvalsHeader() {
      const total = this.approvals.reduce(
        (sum, { approvalsRequired }) => sum + approvalsRequired,
        0,
      );
      return sprintf(this.$options.i18n.approvalsHeader, {
        total,
      });
    },
    statusChecksHeader() {
      return sprintf(this.$options.i18n.statusChecksHeader, {
        total: this.statusChecks.length,
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
      return mergeUrlParams({ state: 'all', search: this.branch }, this.branchesPath);
    },
    matchingBranchesLinkTitle() {
      const total = this.matchingBranchesCount;
      const subject = n__('branch', 'branches', total);
      return sprintf(this.$options.i18n.matchingBranchesLinkTitle, { total, subject });
    },
    approvals() {
      return this.approvalRules?.nodes || [];
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
    />

    <!-- Force push -->
    <strong>{{ $options.i18n.forcePushTitle }}</strong>
    <p>{{ forcePushDescription }}</p>

    <!-- Allowed to merge -->
    <protection
      :header="allowedToMergeHeader"
      :header-link-title="$options.i18n.manageProtectionsLinkTitle"
      :header-link-href="protectedBranchesPath"
      :roles="mergeAccessLevels.roles"
      :users="mergeAccessLevels.users"
      :groups="mergeAccessLevels.groups"
    />

    <!-- Approvals -->
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
      :approvals="approvals"
    />

    <!-- Status checks -->
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
  </div>
</template>

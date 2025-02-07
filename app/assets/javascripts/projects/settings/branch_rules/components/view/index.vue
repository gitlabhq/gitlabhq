<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { GlSprintf, GlLink, GlLoadingIcon, GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { sprintf, n__, s__ } from '~/locale';
import {
  getParameterByName,
  mergeUrlParams,
  visitUrl,
  setUrlParams,
} from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchRulesQuery from 'ee_else_ce/projects/settings/branch_rules/queries/branch_rules_details.query.graphql';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import editBranchRuleMutation from 'ee_else_ce/projects/settings/branch_rules/mutations/edit_branch_rule.mutation.graphql';
import { getAccessLevels, getAccessLevelInputFromEdges } from 'ee_else_ce/projects/settings/utils';
import {
  BRANCH_RULE_DETAILS_LABEL,
  CHANGED_BRANCH_RULE_TARGET,
  CHANGED_ALLOWED_TO_MERGE,
  CHANGED_ALLOWED_TO_PUSH_AND_MERGE,
  CHANGED_ALLOW_FORCE_PUSH,
  UNPROTECTED_BRANCH,
  CHANGED_REQUIRE_CODEOWNER_APPROVAL,
} from 'ee_else_ce/projects/settings/branch_rules/tracking/constants';
import deleteBranchRuleMutation from '../../mutations/branch_rule_delete.mutation.graphql';
import BranchRuleModal from '../../../components/branch_rule_modal.vue';
import Protection from './protection.vue';
import AccessLevelsDrawer from './access_levels_drawer.vue';
import ProtectionToggle from './protection_toggle.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  BRANCH_PARAM_NAME,
  DELETE_RULE_MODAL_ID,
  EDIT_RULE_MODAL_ID,
} from './constants';

const protectedBranchesHelpDocLink = helpPagePath('user/project/repository/branches/protected');
const codeOwnersHelpDocLink = helpPagePath('user/project/codeowners/_index');
const pushRulesHelpDocLink = helpPagePath('user/project/repository/push_rules');
const squashSettingsHelpDocLink = helpPagePath('user/project/merge_requests/squash_and_merge');

export default {
  name: 'RuleView',
  i18n: I18N,
  deleteModalId: DELETE_RULE_MODAL_ID,
  protectedBranchesHelpDocLink,
  codeOwnersHelpDocLink,
  pushRulesHelpDocLink,
  squashSettingsHelpDocLink,
  directives: {
    GlModal: GlModalDirective,
  },
  editModalId: EDIT_RULE_MODAL_ID,
  components: {
    Protection,
    ProtectionToggle,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlButton,
    BranchRuleModal,
    AccessLevelsDrawer,
    PageHeading,
    CrudComponent,
    SettingsSection,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    projectPath: {
      default: '',
    },
    projectId: {
      default: null,
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
    canAdminProtectedBranches: { default: false },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    project: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          buildMissing: this.isAllBranchesRule,
        };
      },
      update({ project: { branchRules, group } }) {
        const branchRule = branchRules.nodes.find((rule) => rule.name === this.branch);
        this.branchRule = branchRule;
        this.branchProtection = branchRule?.branchProtection;
        this.statusChecks = branchRule?.externalStatusChecks?.nodes || [];
        this.matchingBranchesCount = branchRule?.matchingBranchesCount;
        this.groupId = getIdFromGraphQLId(group?.id) || null;
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
      groupId: null,
      matchingBranchesCount: null,
      isAllowedToMergeDrawerOpen: false,
      isAllowedToPushAndMergeDrawerOpen: false,
      isRuleUpdating: false,
      isAllowForcePushLoading: false,
      isCodeOwnersLoading: false,
    };
  },
  computed: {
    forcePushAttributes() {
      const { allowForcePush } = this.branchProtection || {};
      const title = allowForcePush
        ? this.$options.i18n.allowForcePushTitle
        : this.$options.i18n.doesNotAllowForcePushTitle;

      if (!this.glFeatures.editBranchRules) {
        return { title, description: this.$options.i18n.forcePushIconDescription };
      }

      return {
        title,
        description: this.$options.i18n.forcePushDescriptionWithDocs,
      };
    },
    codeOwnersApprovalAttributes() {
      const { codeOwnerApprovalRequired } = this.branchProtection || {};
      const title = codeOwnerApprovalRequired
        ? this.$options.i18n.requiresCodeOwnerApprovalTitle
        : this.$options.i18n.doesNotRequireCodeOwnerApprovalTitle;

      if (!this.glFeatures.editBranchRules) {
        const description = codeOwnerApprovalRequired
          ? this.$options.i18n.requiresCodeOwnerApprovalDescription
          : this.$options.i18n.doesNotRequireCodeOwnerApprovalDescription;

        return { title, description };
      }

      return {
        title,
        description: this.$options.i18n.codeOwnerApprovalDescription,
      };
    },
    mergeAccessLevels() {
      const { mergeAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(mergeAccessLevels);
    },
    pushAccessLevels() {
      const { pushAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(pushAccessLevels);
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
    // needed to override EE component
    statusChecksCount() {
      return '0';
    },
    isAllBranchesRule() {
      return this.branch === this.$options.i18n.allBranches;
    },
    isPredefinedRule() {
      return this.isAllBranchesRule || this.branch === this.$options.i18n.allProtectedBranches;
    },
    hasPushAccessLevelSet() {
      return this.pushAccessLevels?.total > 0;
    },
    accessLevelsDrawerTitle() {
      return this.isAllowedToMergeDrawerOpen
        ? s__('BranchRules|Edit allowed to merge')
        : s__('BranchRules|Edit allowed to push and merge');
    },
    accessLevelsDrawerData() {
      return this.isAllowedToMergeDrawerOpen ? this.mergeAccessLevels : this.pushAccessLevels;
    },
    showStatusChecksSection() {
      return this.showStatusChecks && this.branch !== this.$options.i18n.allProtectedBranches;
    },
    showMergeRequestsSection() {
      return this.showApprovers || this.showSquashSetting;
    },
    showSquashSetting() {
      return this.glFeatures.branchRuleSquashSettings && !this.branch?.includes('*'); // Squash settings are not available for wildcards
    },
    squashOption() {
      return this.branchRule?.squashOption;
    },
  },
  methods: {
    ...mapActions(['setRulesFilter', 'fetchRules']),
    getAccessLevels,
    getAccessLevelInputFromEdges,
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
            InternalEvents.trackEvent(UNPROTECTED_BRANCH, {
              label: BRANCH_RULE_DETAILS_LABEL,
            });
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
    openAllowedToMergeDrawer() {
      this.isAllowedToMergeDrawerOpen = true;
    },
    closeAccessLevelsDrawer() {
      this.isAllowedToMergeDrawerOpen = false;
      this.isAllowedToPushAndMergeDrawerOpen = false;
    },
    openAllowedToPushAndMergeDrawer() {
      this.isAllowedToPushAndMergeDrawerOpen = true;
    },
    onEditRuleTarget(ruleTarget) {
      this.editBranchRule({
        name: ruleTarget,
        trackEvent: CHANGED_BRANCH_RULE_TARGET,
      });
    },
    onEnableForcePushToggle(isChecked) {
      this.isAllowForcePushLoading = true;
      const toastMessage = isChecked
        ? this.$options.i18n.allowForcePushEnabled
        : this.$options.i18n.allowForcePushDisabled;

      this.editBranchRule({
        branchProtection: { allowForcePush: isChecked },
        toastMessage,
        trackEvent: CHANGED_ALLOW_FORCE_PUSH,
      });
    },
    onEnableCodeOwnersToggle(isChecked) {
      this.isCodeOwnersLoading = true;
      const toastMessage = isChecked
        ? this.$options.i18n.codeOwnerApprovalEnabled
        : this.$options.i18n.codeOwnerApprovalDisabled;

      this.editBranchRule({
        branchProtection: { codeOwnerApprovalRequired: isChecked },
        toastMessage,
        trackEvent: CHANGED_REQUIRE_CODEOWNER_APPROVAL,
      });
    },
    onEditAccessLevels(accessLevels) {
      this.isRuleUpdating = true;

      if (this.isAllowedToMergeDrawerOpen) {
        this.editBranchRule({
          branchProtection: { mergeAccessLevels: accessLevels },
          toastMessage: s__('BranchRules|Allowed to merge updated'),
          trackEvent: CHANGED_ALLOWED_TO_MERGE,
        });
      } else if (this.isAllowedToPushAndMergeDrawerOpen) {
        this.editBranchRule({
          branchProtection: { pushAccessLevels: accessLevels },
          toastMessage: s__('BranchRules|Allowed to push and merge updated'),
          trackEvent: CHANGED_ALLOWED_TO_PUSH_AND_MERGE,
        });
      }
    },
    editBranchRule({
      name = this.branchRule.name,
      branchProtection = null,
      toastMessage = '',
      trackEvent = '',
    }) {
      this.$apollo
        .mutate({
          mutation: editBranchRuleMutation,
          variables: {
            input: {
              id: this.branchRule.id,
              name,
              branchProtection: {
                allowForcePush: this.branchProtection.allowForcePush,
                codeOwnerApprovalRequired: this.branchProtection.codeOwnerApprovalRequired,
                pushAccessLevels: this.getAccessLevelInputFromEdges(
                  this.branchProtection.pushAccessLevels.edges,
                ),
                mergeAccessLevels: this.getAccessLevelInputFromEdges(
                  this.branchProtection.mergeAccessLevels.edges,
                ),
                ...(branchProtection || {}),
              },
            },
          },
        })
        .then(({ data: { branchRuleUpdate } }) => {
          if (branchRuleUpdate.errors.length) {
            createAlert({ message: this.$options.i18n.updateBranchRuleError });
            return;
          }

          if (trackEvent.length) {
            InternalEvents.trackEvent(trackEvent, {
              label: BRANCH_RULE_DETAILS_LABEL,
            });
          }

          const isRedirectNeeded = !branchProtection;
          if (isRedirectNeeded) {
            visitUrl(setUrlParams({ branch: name }));
          } else {
            this.closeAccessLevelsDrawer();
            this.$toast.show(toastMessage);
          }
        })
        .catch(() => {
          createAlert({ message: this.$options.i18n.updateBranchRuleError });
        })
        .finally(() => {
          this.isRuleUpdating = false;
          this.isAllowForcePushLoading = false;
          this.isCodeOwnersLoading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.pageTitle">
      <template #actions>
        <gl-button
          v-if="glFeatures.editBranchRules && branchRule && canAdminProtectedBranches"
          v-gl-modal="$options.deleteModalId"
          data-testid="delete-rule-button"
          category="secondary"
          variant="danger"
          :disabled="$apollo.loading"
          >{{ $options.i18n.deleteRule }}
        </gl-button>
      </template>
    </page-heading>

    <gl-loading-icon v-if="$apollo.loading" size="lg" />
    <div v-else-if="!branchRule && !isPredefinedRule">{{ $options.i18n.noData }}</div>
    <div v-else>
      <crud-component :title="$options.i18n.ruleTarget" data-testid="rule-target-card">
        <template #actions>
          <gl-button
            v-if="glFeatures.editBranchRules && !isPredefinedRule && canAdminProtectedBranches"
            v-gl-modal="$options.editModalId"
            data-testid="edit-rule-name-button"
            size="small"
            >{{ $options.i18n.edit }}</gl-button
          >
        </template>

        <div v-if="allBranches" class="gl-mt-2" data-testid="all-branches">*</div>
        <code v-else class="gl-bg-transparent gl-p-0 gl-text-base" data-testid="branch">{{
          branch
        }}</code>
        <p v-if="matchingBranchesCount" class="gl-mb-0 gl-mt-3">
          <gl-link :href="matchingBranchesLinkHref">{{ matchingBranchesLinkTitle }}</gl-link>
        </p>
      </crud-component>

      <settings-section
        v-if="!isPredefinedRule"
        :heading="$options.i18n.protectBranchTitle"
        class="gl-mt-5"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.protectBranchDescription">
            <template #link="{ content }">
              <gl-link :href="$options.protectedBranchesHelpDocLink">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>

        <!-- Allowed to merge -->
        <protection
          :header="$options.i18n.allowedToMergeHeader"
          :count="mergeAccessLevels.total"
          :header-link-title="$options.i18n.manageProtectionsLinkTitle"
          :header-link-href="protectedBranchesPath"
          :roles="mergeAccessLevels.roles"
          :users="mergeAccessLevels.users"
          :groups="mergeAccessLevels.groups"
          :empty-state-copy="$options.i18n.allowedToMergeEmptyState"
          :is-edit-available="canAdminProtectedBranches"
          data-testid="allowed-to-merge-content"
          @edit="openAllowedToMergeDrawer"
        />

        <!-- Allowed to push -->
        <protection
          class="gl-mt-5"
          :header="$options.i18n.allowedToPushHeader"
          :count="pushAccessLevels.total"
          :header-link-title="$options.i18n.manageProtectionsLinkTitle"
          :header-link-href="protectedBranchesPath"
          :roles="pushAccessLevels.roles"
          :users="pushAccessLevels.users"
          :groups="pushAccessLevels.groups"
          :deploy-keys="pushAccessLevels.deployKeys"
          :empty-state-copy="$options.i18n.allowedToPushEmptyState"
          :help-text="$options.i18n.allowedToPushDescription"
          :is-edit-available="canAdminProtectedBranches"
          data-testid="allowed-to-push-content"
          @edit="openAllowedToPushAndMergeDrawer"
        />

        <access-levels-drawer
          :is-open="isAllowedToMergeDrawerOpen || isAllowedToPushAndMergeDrawerOpen"
          :roles="accessLevelsDrawerData.roles"
          :users="accessLevelsDrawerData.users"
          :groups="accessLevelsDrawerData.groups"
          :deploy-keys="accessLevelsDrawerData.deployKeys"
          :is-loading="isRuleUpdating"
          :group-id="groupId"
          :title="accessLevelsDrawerTitle"
          :is-push-access-levels="isAllowedToPushAndMergeDrawerOpen"
          @editRule="onEditAccessLevels"
          @close="closeAccessLevelsDrawer"
        />

        <!-- Force push -->
        <protection-toggle
          v-if="hasPushAccessLevelSet"
          class="gl-mt-6"
          data-testid="force-push-content"
          data-test-id-prefix="force-push"
          :is-protected="branchProtection.allowForcePush"
          :label="$options.i18n.allowForcePushLabel"
          :icon-title="forcePushAttributes.title"
          :description="forcePushAttributes.description"
          :description-link="$options.pushRulesHelpDocLink"
          :is-loading="isAllowForcePushLoading"
          @toggle="onEnableForcePushToggle"
        />

        <!-- EE start -->
        <!-- Code Owners -->
        <protection-toggle
          v-if="showCodeOwners"
          data-testid="code-owners-content"
          data-test-id-prefix="code-owners"
          :is-protected="branchProtection.codeOwnerApprovalRequired"
          :label="$options.i18n.requiresCodeOwnerApprovalLabel"
          :icon-title="codeOwnersApprovalAttributes.title"
          :description="codeOwnersApprovalAttributes.description"
          :description-link="$options.codeOwnersHelpDocLink"
          :is-loading="isCodeOwnersLoading"
          @toggle="onEnableCodeOwnersToggle"
        />
      </settings-section>

      <!-- Merge requests -->
      <settings-section
        v-if="showMergeRequestsSection"
        :heading="$options.i18n.mergeRequestsTitle"
        class="gl-mt-5"
      >
        <!-- eslint-disable-next-line vue/no-undef-components -->
        <approval-rules-app
          v-if="showApprovers"
          :is-mr-edit="false"
          :is-branch-rules-edit="true"
          class="!gl-mt-0"
          @submitted="$apollo.queries.project.refetch()"
        >
          <template #description>
            <gl-sprintf :message="$options.i18n.approvalsDescription">
              <template #link="{ content }">
                <gl-link :href="$options.approvalsHelpDocLink">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </template>

          <template #rules>
            <!-- eslint-disable-next-line vue/no-undef-components -->
            <project-rules :is-branch-rules-edit="true" />
          </template>
        </approval-rules-app>

        <!-- Squash setting-->
        <protection
          v-if="showSquashSetting"
          :header="$options.i18n.squashSettingHeader"
          :empty-state-copy="$options.i18n.squashSettingEmptyState"
          :is-edit-available="false"
          :icon="null"
          class="gl-mt-5"
          data-testid="squash-setting-content"
        >
          <template #description>
            <gl-sprintf :message="$options.i18n.squashSettingHelpText">
              <template #link="{ content }">
                <gl-link :href="$options.squashSettingsHelpDocLink">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </template>
          <template v-if="squashOption && squashOption.option" #content>
            <div>
              <span>{{ squashOption.option }}</span>
              <p class="gl-text-subtle">{{ squashOption.helpText }}</p>
            </div>
          </template>
        </protection>
      </settings-section>

      <!-- Status checks -->
      <settings-section
        v-if="showStatusChecksSection"
        :heading="$options.i18n.statusChecksTitle"
        class="-gl-mt-5"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.statusChecksDescription">
            <template #link="{ content }">
              <gl-link :href="$options.statusChecksHelpDocLink">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>

        <!-- eslint-disable-next-line vue/no-undef-components -->
        <status-checks
          v-if="glFeatures.editBranchRules"
          :branch-rule-id="branchRule && branchRule.id"
          :status-checks="statusChecks"
          :project-path="projectPath"
          :is-all-branches-rule="isAllBranchesRule"
          class="gl-mt-3"
        />

        <protection
          v-else
          data-testid="status-checks-content"
          class="gl-mt-0"
          :header="statusChecksHeader"
          icon="check-circle"
          :count="statusChecksCount"
          :header-link-title="$options.i18n.statusChecksLinkTitle"
          :header-link-href="statusChecksPath"
          :status-checks="statusChecks"
          :empty-state-copy="$options.i18n.statusChecksEmptyState"
        />
      </settings-section>

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
        @primary="onEditRuleTarget"
      />
    </div>
  </div>
</template>

<script>
import { GlToggle, GlLink, GlButton, GlCard, GlSprintf } from '@gitlab/ui';
import DuoDependencyBumpProfileModal from 'ee_component/pages/projects/shared/permissions/components/duo_dependency_bump_profile_modal.vue';
import DuoReadinessPlatformRow from 'ee_component/pages/projects/shared/permissions/components/duo_readiness_platform_row.vue';
import projectAutoRemediationProfileQuery from 'ee_else_ce/pages/projects/shared/permissions/graphql/project_auto_remediation_profile.query.graphql';
import attachProfileMutation from 'ee_else_ce/pages/projects/shared/permissions/graphql/auto_remediation_profile_attach.mutation.graphql';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';
import {
  amazonQHelpPath,
  duoFlowHelpPath,
  duoHelpPath,
  ALL_SETTINGS,
  DUO_SAST_VR_WORKFLOW_ENABLED,
  DUO_SAST_FALSE_POSITIVE_DETECTION_ENABLED,
  DUO_SECRET_DETECTION_FP_ENABLED,
} from '../constants';
import ProjectSettingRow from './project_setting_row.vue';
import ExclusionSettings from './exclusion_settings.vue';
import DuoReadinessRow, { STATUS_DONE, STATUS_TODO, STATUS_BLOCKED } from './duo_readiness_row.vue';
import DuoLocalSetupSection from './duo_local_setup_section.vue';

const AUTO_REMEDIATION_PROFILE_SCAN_TYPE = 'DEPENDENCY_SCANNING_POST_PROCESSING';
const AUTO_REMEDIATION_PROFILE_VIRTUAL_ID =
  'gid://gitlab/Security::ScanProfile/dependency_scanning_post_processing';

export default {
  name: 'GitlabDuoSettings',
  components: {
    GlToggle,
    GlSprintf,
    GlLink,
    GlButton,
    GlCard,
    ProjectSettingRow,
    CascadingLockIcon,
    ExclusionSettings,
    DuoDependencyBumpProfileModal,
    DuoReadinessRow,
    DuoReadinessPlatformRow,
    DuoLocalSetupSection,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    governancePath: {
      type: String,
      required: false,
      default: '',
    },
    duoAvailabilityCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoRemoteFlowsCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoFoundationalFlowsCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    aiAuditEventsStorageEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    aiAuditEventsStorageCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },

    duoFeaturesEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    amazonQAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    amazonQAutoReviewEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoFeaturesLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    licensedAiFeaturesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoContextExclusionSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    initialDuoRemoteFlowsAvailability: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDuoFoundationalFlowsAvailability: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDuoSastFalsePositiveDetectionEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDuoSecretDetectionFpEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDuoDependencyBumpBreakingChangesEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    projectGlobalId: {
      type: String,
      required: false,
      default: '',
    },
    initialDuoSastVrWorkflowEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    ultimateFeaturesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    toolApprovalForSessionCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    initialToolApprovalForSessionEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    toolApprovalForSessionLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    dapSessionTrackingAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDapSessionTrackingEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoReadiness: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoReadinessAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    visibleSettings: {
      type: Array,
      required: false,
      default: () => [ALL_SETTINGS],
    },
  },
  data() {
    return {
      autoReviewEnabled: this.amazonQAutoReviewEnabled,
      duoEnabled: this.duoFeaturesEnabled,
      exclusionRules: this.duoContextExclusionSettings?.exclusionRules || [],
      duoRemoteFlowsAvailability: this.initialDuoRemoteFlowsAvailability,
      duoFoundationalFlowsAvailability: this.initialDuoFoundationalFlowsAvailability,
      duoSastFalsePositiveDetectionEnabled: this.initialDuoSastFalsePositiveDetectionEnabled,
      duoSecretDetectionFpEnabled: this.initialDuoSecretDetectionFpEnabled,
      duoDependencyBumpBreakingChangesEnabled: this.initialDuoDependencyBumpBreakingChangesEnabled,
      duoSastVrWorkflowEnabled: this.initialDuoSastVrWorkflowEnabled,
      toolApprovalForSessionEnabled: this.initialToolApprovalForSessionEnabled,
      dapSessionTrackingEnabled: this.initialDapSessionTrackingEnabled,
      auditEventsStorageEnabled: this.aiAuditEventsStorageEnabled,
      showAutoRemediationModal: false,
      autoRemediationModalLoading: false,
    };
  },
  computed: {
    duoEnabledSetting() {
      if (this.amazonQAvailable) {
        return {
          label: s__('ProjectSettings|Amazon Q'),
          helpText: s__('ProjectSettings|This project can use Amazon Q.'),
          helpPath: amazonQHelpPath,
        };
      }
      if (this.licensedAiFeaturesAvailable) {
        return {
          label: s__('ProjectSettings|GitLab Duo'),
          helpText: s__('ProjectSettings|Use AI-native features in this project.'),
          helpPath: duoHelpPath,
        };
      }

      return null;
    },
    showAvailabilityCascadingButton() {
      return (
        this.duoFeaturesLocked &&
        this.duoAvailabilityCascadingSettings &&
        Object.keys(this.duoAvailabilityCascadingSettings).length
      );
    },
    showRemoteFlowsCascadingLock() {
      return (
        this.duoRemoteFlowsCascadingSettings?.lockedByAncestor ||
        this.duoRemoteFlowsCascadingSettings?.lockedByApplicationSetting
      );
    },
    areFoundationalFlowsLocked() {
      return (
        this.duoFoundationalFlowsCascadingSettings?.lockedByAncestor ||
        this.duoFoundationalFlowsCascadingSettings?.lockedByApplicationSetting
      );
    },
    showToolApprovalCascadingLock() {
      return (
        this.toolApprovalForSessionLocked &&
        (this.toolApprovalForSessionCascadingSettings?.lockedByAncestor ||
          this.toolApprovalForSessionCascadingSettings?.lockedByApplicationSetting)
      );
    },
    showAuditEventsStorageCascadingLock() {
      return (
        this.aiAuditEventsStorageCascadingSettings?.lockedByAncestor ||
        this.aiAuditEventsStorageCascadingSettings?.lockedByApplicationSetting
      );
    },
    showSastVrWorkflow() {
      return this.ultimateFeaturesAvailable;
    },
    // The readiness card replaces the flat Duo/flow toggles. Amazon Q projects keep the old
    // layout: they have no flow settings, so a "run agents here" card would be meaningless.
    showReadinessCard() {
      return (
        this.duoReadinessAvailable &&
        Boolean(this.duoEnabledSetting) &&
        this.showAllSettings &&
        !this.amazonQAvailable
      );
    },
    // The design's blocked cascade: with the Agent Platform off above the project, nothing
    // below its row is actionable, so every row reads blocked and its control is disabled.
    platformEnabled() {
      return Boolean(this.duoReadiness.platformEnabled);
    },
    duoRowStatus() {
      if (!this.platformEnabled) return STATUS_BLOCKED;

      return this.duoEnabled ? STATUS_DONE : STATUS_TODO;
    },
    flowExecutionRowStatus() {
      if (!this.platformEnabled || !this.duoEnabled) return STATUS_BLOCKED;

      return this.duoRemoteFlowsAvailability ? STATUS_DONE : STATUS_TODO;
    },
    foundationalFlowsRowStatus() {
      if (!this.platformEnabled || !this.duoEnabled || !this.duoRemoteFlowsAvailability) {
        return STATUS_BLOCKED;
      }

      return this.duoFoundationalFlowsAvailability ? STATUS_DONE : STATUS_TODO;
    },
    showAllSettings() {
      return this.visibleSettings.includes(ALL_SETTINGS);
    },
  },
  watch: {
    duoFeaturesEnabled(isEnabled) {
      if (this.amazonQAvailable) {
        this.autoReviewEnabled = isEnabled;
      } else {
        this.autoReviewEnabled = false;
      }
    },
  },
  methods: {
    handleExclusionRulesUpdate(rules) {
      this.exclusionRules = rules;
      this.$nextTick(() => {
        this.$el.closest('form')?.submit();
      });
    },
    isSettingVisible(name) {
      return this.showAllSettings || this.visibleSettings.includes(name);
    },
    async handleDependencyBumpToggleChange(newValue) {
      if (!newValue) {
        this.duoDependencyBumpBreakingChangesEnabled = false;
        return;
      }

      if (!this.projectFullPath) {
        this.duoDependencyBumpBreakingChangesEnabled = true;
        return;
      }

      try {
        const { data } = await this.$apollo.query({
          query: projectAutoRemediationProfileQuery,
          variables: { fullPath: this.projectFullPath },
          fetchPolicy: 'network-only',
        });

        const profiles = data?.project?.securityScanProfiles ?? [];
        const profileEnabled = profiles.some(
          (p) => p.scanType === AUTO_REMEDIATION_PROFILE_SCAN_TYPE,
        );

        if (profileEnabled) {
          this.duoDependencyBumpBreakingChangesEnabled = true;
        } else {
          this.showAutoRemediationModal = true;
        }
      } catch {
        // If the query fails, enable the toggle without prompting
        this.duoDependencyBumpBreakingChangesEnabled = true;
      }
    },
    async onAutoRemediationModalConfirm() {
      this.autoRemediationModalLoading = true;
      try {
        await this.$apollo.mutate({
          mutation: attachProfileMutation,
          variables: {
            input: {
              securityScanProfileId: AUTO_REMEDIATION_PROFILE_VIRTUAL_ID,
              projectIds: [this.projectGlobalId],
            },
          },
        });
      } catch {
        // Non-blocking: profile attach failure should not prevent enabling the toggle
      } finally {
        this.autoRemediationModalLoading = false;
        this.showAutoRemediationModal = false;
        this.duoDependencyBumpBreakingChangesEnabled = true;
      }
    },
    onAutoRemediationModalCancel() {
      this.showAutoRemediationModal = false;
      this.duoDependencyBumpBreakingChangesEnabled = true;
    },
    onAutoRemediationModalHide() {
      this.showAutoRemediationModal = false;
      this.duoDependencyBumpBreakingChangesEnabled = false;
    },
  },
  duoFlowHelpPath,
  DUO_SAST_VR_WORKFLOW_ENABLED,
  DUO_SAST_FALSE_POSITIVE_DETECTION_ENABLED,
  DUO_SECRET_DETECTION_FP_ENABLED,
  i18n: {
    readinessHeading: s__('DuoAgentPlatform|Run GitLab Duo agents on this project'),
    requiredHeading: s__('DuoAgentPlatform|Required'),
    requiredSubtitle: s__(
      'DuoAgentPlatform|Agents cannot run here until everything below is in place.',
    ),
    otherSettingsHeading: s__('DuoAgentPlatform|Other Duo settings'),
    otherSettingsSubtitle: s__('DuoAgentPlatform|Project-wide behavior, unrelated to readiness.'),
    saveChanges: __('Save changes'),
    saveChangesAriaLabel: __('Save changes for GitLab Duo'),
    governanceTitle: s__('AiPowered|Governance'),
    governanceDescription: s__('AiPowered|Control how your AI-powered features are used.'),
    governanceAction: s__('AiPowered|Change governance'),
  },
};
</script>

<template>
  <div class="project-visibility-setting" data-testid="gitlab-duo-settings">
    <div v-if="showReadinessCard" class="gl-mb-6" data-testid="duo-readiness-block">
      <h3 class="gl-heading-3 gl-mb-2" data-testid="readiness-heading">
        {{ $options.i18n.readinessHeading }}
      </h3>

      <div class="gl-mb-3 gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
        <span class="gl-font-bold">{{ $options.i18n.requiredHeading }}</span>
        <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.requiredSubtitle }}</span>
      </div>

      <div class="gl-border gl-overflow-hidden gl-rounded-lg">
        <duo-readiness-platform-row :readiness="duoReadiness" />

        <duo-readiness-row
          :title="duoEnabledSetting.label"
          :description="duoEnabledSetting.helpText"
          :status="duoRowStatus"
          data-testid="duo-row"
        >
          <template #title-icon>
            <cascading-lock-icon
              v-if="showAvailabilityCascadingButton"
              data-testid="duo-cascading-lock-icon"
              :is-locked-by-group-ancestor="duoAvailabilityCascadingSettings.lockedByAncestor"
              :is-locked-by-application-settings="
                duoAvailabilityCascadingSettings.lockedByApplicationSetting
              "
              :ancestor-namespace="duoAvailabilityCascadingSettings.ancestorNamespace"
              class="gl-ml-1"
            />
          </template>
          <gl-toggle
            v-model="duoEnabled"
            :disabled="!platformEnabled || duoFeaturesLocked"
            :label="duoEnabledSetting.label"
            label-position="hidden"
            name="project[project_setting_attributes][duo_features_enabled]"
            data-testid="duo_features_enabled_toggle"
          />
        </duo-readiness-row>

        <duo-readiness-row
          :title="s__('DuoAgentPlatform|Allow flow execution')"
          :status="flowExecutionRowStatus"
          data-testid="flow-execution-row"
        >
          <template #title-icon>
            <cascading-lock-icon
              v-if="showRemoteFlowsCascadingLock"
              data-testid="duo-flows-cascading-lock-icon"
              :is-locked-by-group-ancestor="duoRemoteFlowsCascadingSettings.lockedByAncestor"
              :is-locked-by-application-settings="
                duoRemoteFlowsCascadingSettings.lockedByApplicationSetting
              "
              :ancestor-namespace="duoRemoteFlowsCascadingSettings.ancestorNamespace"
              class="gl-ml-1"
            />
          </template>
          <template #description>
            {{ s__('DuoAgentPlatform|Allow GitLab Duo agents to execute flows in this project.') }}
            <gl-sprintf :message="s__('DuoAgentPlatform|%{linkStart}What are flows?%{linkEnd}')">
              <template #link="{ content }">
                <gl-link :href="$options.duoFlowHelpPath" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
          <gl-toggle
            v-model="duoRemoteFlowsAvailability"
            :disabled="!platformEnabled || !duoEnabled || showRemoteFlowsCascadingLock"
            :label="s__('DuoAgentPlatform|Remote GitLab Duo Flows')"
            label-position="hidden"
            name="project[project_setting_attributes][duo_remote_flows_enabled]"
            data-testid="duo-remote-flows-enabled"
          />
        </duo-readiness-row>

        <duo-readiness-row
          nested
          :title="s__('DuoAgentPlatform|Allow foundational flows')"
          :description="
            s__(
              'DuoAgentPlatform|Allow GitLab Duo agents to execute foundational flows in this project.',
            )
          "
          :status="foundationalFlowsRowStatus"
          data-testid="foundational-flows-row"
        >
          <template #title-icon>
            <cascading-lock-icon
              v-if="areFoundationalFlowsLocked"
              data-testid="duo-foundational-flows-cascading-lock-icon"
              :is-locked-by-group-ancestor="duoFoundationalFlowsCascadingSettings.lockedByAncestor"
              :is-locked-by-application-settings="
                duoFoundationalFlowsCascadingSettings.lockedByApplicationSetting
              "
              :ancestor-namespace="duoFoundationalFlowsCascadingSettings.ancestorNamespace"
              class="gl-ml-1"
            />
          </template>
          <gl-toggle
            v-model="duoFoundationalFlowsAvailability"
            :disabled="
              !platformEnabled ||
              !duoEnabled ||
              !duoRemoteFlowsAvailability ||
              areFoundationalFlowsLocked
            "
            :label="s__('DuoAgentPlatform|Foundational GitLab Duo Flows')"
            label-position="hidden"
            name="project[project_setting_attributes][duo_foundational_flows_enabled]"
            data-testid="duo-foundational-flows-enabled"
          />
        </duo-readiness-row>
      </div>

      <duo-local-setup-section class="gl-mt-5" />
    </div>
    <project-setting-row
      v-if="duoEnabledSetting && !showReadinessCard"
      data-testid="duo-settings"
      :label="duoEnabledSetting.label"
      :help-text="duoEnabledSetting.helpText"
      :help-path="duoEnabledSetting.helpPath"
      :locked="duoFeaturesLocked"
    >
      <template #label-icon>
        <cascading-lock-icon
          v-if="showAvailabilityCascadingButton"
          data-testid="duo-cascading-lock-icon"
          :is-locked-by-group-ancestor="duoAvailabilityCascadingSettings.lockedByAncestor"
          :is-locked-by-application-settings="
            duoAvailabilityCascadingSettings.lockedByApplicationSetting
          "
          :ancestor-namespace="duoAvailabilityCascadingSettings.ancestorNamespace"
          class="gl-ml-1"
        />
      </template>
      <gl-toggle
        v-if="showAllSettings"
        v-model="duoEnabled"
        class="gl-mt-2"
        :disabled="duoFeaturesLocked"
        :label="duoEnabledSetting.label"
        label-position="hidden"
        name="project[project_setting_attributes][duo_features_enabled]"
        data-testid="duo_features_enabled_toggle"
      />
      <div
        v-if="amazonQAvailable"
        class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5 gl-pl-5 @md/panel:gl-pl-7"
      >
        <project-setting-row
          v-if="showAllSettings"
          :label="s__('AI|Enable Auto Review')"
          class="gl-mt-5"
          :help-text="
            s__('AI|When a merge request is created, automatically starts an Amazon Q review')
          "
        >
          <gl-toggle
            v-model="autoReviewEnabled"
            class="gl-mt-2"
            :disabled="duoFeaturesLocked || !duoEnabled"
            :label="s__('AI|Auto Review')"
            label-position="hidden"
            name="project[amazon_q_auto_review_enabled]"
            data-testid="amazon-q-auto-review-enabled"
          />
        </project-setting-row>
      </div>
    </project-setting-row>

    <!-- Everything below the card is project-wide behaviour rather than readiness, so the
         design separates it under its own heading. Only shown alongside the card; without it
         the page keeps its existing ungrouped layout. -->
    <div v-if="showReadinessCard" class="gl-border-t gl-mb-5 gl-pt-5">
      <div class="gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
        <span class="gl-font-bold">{{ $options.i18n.otherSettingsHeading }}</span>
        <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.otherSettingsSubtitle }}</span>
      </div>
    </div>

    <div
      v-if="duoEnabled && !amazonQAvailable"
      class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5"
    >
      <!-- Rendered here only while the readiness card is off; the card renders them as rows. -->
      <project-setting-row
        v-if="showAllSettings && !showReadinessCard"
        :label="s__('DuoAgentPlatform|Allow flow execution')"
        class="gl-mt-5"
        :help-text="
          s__('DuoAgentPlatform|Allow GitLab Duo agents to execute flows in this project.')
        "
      >
        <template #label-icon>
          <cascading-lock-icon
            v-if="showRemoteFlowsCascadingLock"
            data-testid="duo-flows-cascading-lock-icon"
            :is-locked-by-group-ancestor="duoRemoteFlowsCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              duoRemoteFlowsCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="duoRemoteFlowsCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          v-model="duoRemoteFlowsAvailability"
          class="gl-mt-2"
          :disabled="!duoEnabled || showRemoteFlowsCascadingLock"
          :label="s__('DuoAgentPlatform|Remote GitLab Duo Flows')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_remote_flows_enabled]"
          data-testid="duo-remote-flows-enabled"
        />
        <template #help-link>
          <gl-sprintf :message="s__('DuoAgentPlatform|%{linkStart}What are flows%{linkEnd}?')">
            <template #link="{ content }">
              <gl-link :href="$options.duoFlowHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </project-setting-row>
      <project-setting-row
        v-if="showAllSettings && !showReadinessCard"
        :label="s__('DuoAgentPlatform|Allow foundational flows')"
        :help-text="
          s__(
            'DuoAgentPlatform|Allow GitLab Duo agents to execute foundational flows in this project.',
          )
        "
      >
        <template #label-icon>
          <cascading-lock-icon
            v-if="areFoundationalFlowsLocked"
            data-testid="duo-foundational-flows-cascading-lock-icon"
            :is-locked-by-group-ancestor="duoFoundationalFlowsCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              duoFoundationalFlowsCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="duoFoundationalFlowsCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          v-model="duoFoundationalFlowsAvailability"
          class="gl-mt-2"
          :disabled="!duoEnabled || !duoRemoteFlowsAvailability || areFoundationalFlowsLocked"
          :label="s__('DuoAgentPlatform|Foundational GitLab Duo Flows')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_foundational_flows_enabled]"
          data-testid="duo-foundational-flows-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="showAllSettings"
        :label="s__('AiPowered|Tool approval for sessions')"
        class="gl-mt-5"
        :help-text="s__('AiPowered|Allow users to approve tools for a session in the IDE and CLI.')"
        :locked="showToolApprovalCascadingLock"
      >
        <template #label-icon>
          <cascading-lock-icon
            v-if="showToolApprovalCascadingLock"
            data-testid="tool-approval-cascading-lock-icon"
            :is-locked-by-group-ancestor="toolApprovalForSessionCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              toolApprovalForSessionCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="toolApprovalForSessionCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          v-model="toolApprovalForSessionEnabled"
          class="gl-mt-2"
          :disabled="!duoEnabled || showToolApprovalCascadingLock"
          :label="s__('AiPowered|Tool approval for sessions')"
          label-position="hidden"
          name="project[project_setting_attributes][tool_approval_for_session_enabled]"
          data-testid="tool-approval-for-session-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="dapSessionTrackingAvailable && showAllSettings"
        :label="s__('DuoAgentPlatform|Track GitLab Duo Agent Platform sessions in commits')"
        class="gl-mt-5"
        :help-text="
          s__(
            'DuoAgentPlatform|Add a session URL to commits authored by GitLab Duo Agent Platform, so reviewers can trace AI-assisted changes back to the originating session.',
          )
        "
      >
        <gl-toggle
          v-model="dapSessionTrackingEnabled"
          class="gl-mt-2"
          :disabled="duoFeaturesLocked || !duoEnabled"
          :label="s__('DuoAgentPlatform|Track GitLab Duo Agent Platform sessions in commits')"
          label-position="hidden"
          name="project[project_setting_attributes][dap_session_tracking_enabled]"
          data-testid="dap-session-tracking-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="glFeatures.agentArtifactsPage && showAllSettings"
        :label="s__('AiPowered|Store AI audit events')"
        class="gl-mt-5"
        :help-text="
          s__(
            'AiPowered|When you turn on this setting, GitLab stores new AI audit events to the database or ClickHouse. Real-time streaming of AI audit events is not affected.',
          )
        "
        :locked="showAuditEventsStorageCascadingLock"
      >
        <template #label-icon>
          <cascading-lock-icon
            v-if="showAuditEventsStorageCascadingLock"
            data-testid="ai-audit-events-storage-cascading-lock-icon"
            :is-locked-by-group-ancestor="aiAuditEventsStorageCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              aiAuditEventsStorageCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="aiAuditEventsStorageCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          v-model="auditEventsStorageEnabled"
          class="gl-mt-2"
          :disabled="showAuditEventsStorageCascadingLock"
          :label="s__('AiPowered|Store AI audit events')"
          label-position="hidden"
          name="project[project_setting_attributes][ai_audit_events_storage_enabled]"
          data-testid="ai-audit-events-storage-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="
          ultimateFeaturesAvailable &&
          isSettingVisible($options.DUO_SAST_FALSE_POSITIVE_DETECTION_ENABLED)
        "
        :label="s__('DuoSAST|Turn on SAST false positive detection')"
        class="gl-mt-5"
        :help-text="
          s__('DuoSAST|Use false positive detection for vulnerabilities on the default branch')
        "
      >
        <gl-toggle
          v-model="duoSastFalsePositiveDetectionEnabled"
          class="gl-mt-2"
          :disabled="!duoEnabled"
          :label="s__('DuoSAST|Turn on SAST false positive detection')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_sast_fp_detection_enabled]"
          data-testid="duo-sast-fp-detection-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="
          ultimateFeaturesAvailable && isSettingVisible($options.DUO_SECRET_DETECTION_FP_ENABLED)
        "
        :label="s__('DuoSecretDetection|Turn on Secret Detection false positive detection')"
        class="gl-mt-5"
        :help-text="
          s__(
            'DuoSecretDetection|Use false positive detection for Secret Detection vulnerabilities on the default branch',
          )
        "
      >
        <gl-toggle
          v-model="duoSecretDetectionFpEnabled"
          class="gl-mt-2"
          :disabled="!duoEnabled"
          :label="s__('DuoSecretDetection|Turn on Secret Detection false positive detection')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_secret_detection_fp_enabled]"
          data-testid="duo-secret-detection-fp-enabled"
        />
      </project-setting-row>
      <project-setting-row
        v-if="
          glFeatures.enableDependencyBumpBreakingChanges &&
          ultimateFeaturesAvailable &&
          showAllSettings
        "
        :label="s__('DuoDependencyBump|Turn on Agentic Breaking Change Resolution')"
        class="gl-mt-5"
        :help-text="
          s__(
            'DuoDependencyBump|Use AI to analyze and fix breaking changes in failed pipelines for dependency bump merge requests',
          )
        "
      >
        <gl-toggle
          :value="duoDependencyBumpBreakingChangesEnabled"
          class="gl-mt-2"
          :disabled="!duoEnabled"
          :label="s__('DuoDependencyBump|Turn on Agentic Breaking Change Resolution')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_dependency_bump_breaking_changes_enabled]"
          data-testid="duo-dependency-bump-breaking-changes-enabled"
          @change="handleDependencyBumpToggleChange"
        />
      </project-setting-row>
      <duo-dependency-bump-profile-modal
        :visible="showAutoRemediationModal"
        :is-loading="autoRemediationModalLoading"
        @confirm="onAutoRemediationModalConfirm"
        @cancel="onAutoRemediationModalCancel"
        @hide="onAutoRemediationModalHide"
      />
      <project-setting-row
        v-if="showSastVrWorkflow && isSettingVisible($options.DUO_SAST_VR_WORKFLOW_ENABLED)"
        :label="s__('DuoSAST|Turn on SAST vulnerability resolution workflow')"
        class="gl-mt-5"
        :help-text="
          s__(
            'DuoSAST|Use vulnerability resolution workflow for vulnerabilities on the default branch',
          )
        "
      >
        <gl-toggle
          v-model="duoSastVrWorkflowEnabled"
          class="gl-mt-2"
          :disabled="!duoEnabled"
          :label="s__('DuoSAST|Turn on SAST vulnerability resolution workflow')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_sast_vr_workflow_enabled]"
          data-testid="duo-sast-vr-workflow-enabled"
        />
      </project-setting-row>
    </div>

    <exclusion-settings
      v-if="showAllSettings"
      class="gl-mt-6"
      :exclusion-rules="exclusionRules"
      @update="handleExclusionRulesUpdate"
    />

    <!-- Hidden inputs for form submission -->
    <div v-if="exclusionRules.length > 0 && showAllSettings">
      <input
        v-for="(rule, index) in exclusionRules"
        :key="index"
        type="hidden"
        :name="`project[project_setting_attributes][duo_context_exclusion_settings][exclusion_rules][]`"
        :value="rule"
      />
    </div>

    <!-- need to use a null for empty array due to strong params deep_munge -->
    <div v-if="exclusionRules.length === 0 && showAllSettings">
      <input
        type="hidden"
        :name="`project[project_setting_attributes][duo_context_exclusion_settings][exclusion_rules]`"
        data-testid="exclusion-rule-input-null"
        :value="null"
      />
    </div>

    <gl-card
      v-if="governancePath"
      class="gl-mt-5"
      header-class="gl-heading-scale-300"
      footer-class="gl-bg-transparent gl-border-none gl-flex gl-justify-end"
      data-testid="duo-governance-info-card"
    >
      <template #header>
        <h3 class="gl-m-0" data-testid="duo-governance-info-card-header">
          {{ $options.i18n.governanceTitle }}
        </h3>
      </template>
      <template #default>
        <p class="gl-mb-0" data-testid="duo-governance-info-card-description">
          {{ $options.i18n.governanceDescription }}
        </p>
      </template>
      <template #footer>
        <gl-button
          category="primary"
          variant="default"
          :href="governancePath"
          data-testid="duo-governance-link"
        >
          {{ $options.i18n.governanceAction }}
        </gl-button>
      </template>
    </gl-card>

    <gl-button
      variant="confirm"
      type="submit"
      class="gl-mt-6"
      :aria-label="$options.i18n.saveChangesAriaLabel"
      data-testid="gitlab-duo-save-button"
    >
      {{ $options.i18n.saveChanges }}
    </gl-button>
  </div>
</template>

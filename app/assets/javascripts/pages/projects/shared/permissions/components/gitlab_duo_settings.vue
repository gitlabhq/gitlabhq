<script>
import { GlToggle, GlLink, GlButton, GlCard, GlSprintf } from '@gitlab/ui';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';

import {
  amazonQHelpPath,
  duoFlowHelpPath,
  duoHelpPath,
  ALL_SETTINGS,
  DUO_SAST_VR_WORKFLOW_ENABLED,
} from '../constants';
import ProjectSettingRow from './project_setting_row.vue';
import ExclusionSettings from './exclusion_settings.vue';

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
    initialDuoSastFpDetectionEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialDuoSecretDetectionFpEnabled: {
      type: Boolean,
      required: false,
      default: false,
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
      duoSastFpDetectionEnabled: this.initialDuoSastFpDetectionEnabled,
      duoSecretDetectionFpEnabled: this.initialDuoSecretDetectionFpEnabled,
      duoSastVrWorkflowEnabled: this.initialDuoSastVrWorkflowEnabled,
      toolApprovalForSessionEnabled: this.initialToolApprovalForSessionEnabled,
      dapSessionTrackingEnabled: this.initialDapSessionTrackingEnabled,
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
    showSastVrWorkflow() {
      return this.glFeatures.enableVulnerabilityResolution && this.ultimateFeaturesAvailable;
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
  },
  duoFlowHelpPath,
  DUO_SAST_VR_WORKFLOW_ENABLED,
  i18n: {
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
    <project-setting-row
      v-if="duoEnabledSetting"
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
      <div
        v-else-if="duoEnabled"
        class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5"
      >
        <project-setting-row
          v-if="showAllSettings"
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
          v-if="showAllSettings"
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
          :help-text="
            s__('AiPowered|Allow users to approve tools for a session in the IDE and CLI.')
          "
          :locked="showToolApprovalCascadingLock"
        >
          <template #label-icon>
            <cascading-lock-icon
              v-if="showToolApprovalCascadingLock"
              data-testid="tool-approval-cascading-lock-icon"
              :is-locked-by-group-ancestor="
                toolApprovalForSessionCascadingSettings.lockedByAncestor
              "
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
          v-if="ultimateFeaturesAvailable && showAllSettings"
          :label="s__('DuoSAST|Turn on SAST false positive detection')"
          class="gl-mt-5"
          :help-text="
            s__('DuoSAST|Use false positive detection for vulnerabilities on the default branch')
          "
        >
          <gl-toggle
            v-model="duoSastFpDetectionEnabled"
            class="gl-mt-2"
            :disabled="!duoEnabled"
            :label="s__('DuoSAST|Turn on SAST false positive detection')"
            label-position="hidden"
            name="project[project_setting_attributes][duo_sast_fp_detection_enabled]"
            data-testid="duo-sast-fp-detection-enabled"
          />
        </project-setting-row>
        <project-setting-row
          v-if="glFeatures.duoSecretDetectionFalsePositive && showAllSettings"
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
    </project-setting-row>

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

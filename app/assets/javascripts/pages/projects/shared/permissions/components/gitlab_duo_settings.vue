<script>
import { GlToggle, GlLink, GlButton, GlSprintf } from '@gitlab/ui';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';

import { amazonQHelpPath, duoFlowHelpPath, duoHelpPath } from '../constants';
import ProjectSettingRow from './project_setting_row.vue';
import ExclusionSettings from './exclusion_settings.vue';

export default {
  name: 'GitlabDuoSettings',
  components: {
    GlToggle,
    GlSprintf,
    GlLink,
    GlButton,
    ProjectSettingRow,
    CascadingLockIcon,
    ExclusionSettings,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
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
    duoSastFpDetectionCascadingSettings: {
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
    experimentFeaturesEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    paidDuoTier: {
      type: Boolean,
      required: false,
      default: false,
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
    };
  },
  computed: {
    areDuoFlowsAvailable() {
      return this.duoEnabled && this.glFeatures.duoWorkflowInCi;
    },
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
    shouldShowExclusionSettings() {
      return (
        this.licensedAiFeaturesAvailable &&
        this.showDuoContextExclusion &&
        this.experimentFeaturesEnabled &&
        this.paidDuoTier
      );
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
    showSastFpDetectionCascadingLock() {
      return (
        this.duoSastFpDetectionCascadingSettings?.lockedByAncestor ||
        this.duoSastFpDetectionCascadingSettings?.lockedByApplicationSetting
      );
    },
    showDuoContextExclusion() {
      return this.glFeatures.useDuoContextExclusion;
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
  },
  duoFlowHelpPath,
  i18n: {
    saveChanges: __('Save changes'),
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
        v-else-if="areDuoFlowsAvailable"
        class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5"
      >
        <project-setting-row
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
            :disabled="duoFeaturesLocked || !duoEnabled || showRemoteFlowsCascadingLock"
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
          v-if="glFeatures.duoFoundationalFlows"
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
            :disabled="
              duoFeaturesLocked ||
              !duoEnabled ||
              !duoRemoteFlowsAvailability ||
              areFoundationalFlowsLocked
            "
            :label="s__('DuoAgentPlatform|Foundational GitLab Duo Flows')"
            label-position="hidden"
            name="project[project_setting_attributes][duo_foundational_flows_enabled]"
            data-testid="duo-foundational-flows-enabled"
          />
        </project-setting-row>
        <project-setting-row
          v-if="glFeatures.aiExperimentSastFpDetection"
          :label="s__('DuoSAST|Turn on GitLab Duo SAST False Positive Detection')"
          class="gl-mt-5"
          :help-text="
            s__('DuoSAST|Use false positive detection for vulnerabilities on the default branch')
          "
        >
          <template #label-icon>
            <cascading-lock-icon
              v-if="showSastFpDetectionCascadingLock"
              data-testid="duo-sast-fp-detection-cascading-lock-icon"
              :is-locked-by-group-ancestor="duoSastFpDetectionCascadingSettings.lockedByAncestor"
              :is-locked-by-application-settings="
                duoSastFpDetectionCascadingSettings.lockedByApplicationSetting
              "
              :ancestor-namespace="duoSastFpDetectionCascadingSettings.ancestorNamespace"
              class="gl-ml-1"
            />
          </template>
          <gl-toggle
            v-model="duoSastFpDetectionEnabled"
            class="gl-mt-2"
            :disabled="duoFeaturesLocked || !duoEnabled || showSastFpDetectionCascadingLock"
            :label="s__('DuoSAST|Turn on GitLab Duo SAST False Positive Detection')"
            label-position="hidden"
            name="project[project_setting_attributes][duo_sast_fp_detection_enabled]"
            data-testid="duo-sast-fp-detection-enabled"
          />
        </project-setting-row>
      </div>
    </project-setting-row>

    <exclusion-settings
      v-if="shouldShowExclusionSettings"
      class="gl-mt-6"
      :exclusion-rules="exclusionRules"
      @update="handleExclusionRulesUpdate"
    />

    <!-- Hidden inputs for form submission -->
    <div v-if="exclusionRules.length > 0">
      <input
        v-for="(rule, index) in exclusionRules"
        :key="index"
        type="hidden"
        :name="`project[project_setting_attributes][duo_context_exclusion_settings][exclusion_rules][]`"
        :value="rule"
      />
    </div>

    <!-- need to use a null for empty array due to strong params deep_munge -->
    <div v-if="exclusionRules.length === 0">
      <input
        type="hidden"
        :name="`project[project_setting_attributes][duo_context_exclusion_settings][exclusion_rules]`"
        data-testid="exclusion-rule-input-null"
        :value="null"
      />
    </div>

    <gl-button
      variant="confirm"
      type="submit"
      class="gl-mt-6"
      data-testid="gitlab-duo-save-button"
      :disabled="duoFeaturesLocked"
    >
      {{ $options.i18n.saveChanges }}
    </gl-button>
  </div>
</template>

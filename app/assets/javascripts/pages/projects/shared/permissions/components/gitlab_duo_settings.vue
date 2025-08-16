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
    cascadingSettingsData: {
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
    initialDuoFlowEnabled: {
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
      duoFlowEnabled: this.initialDuoFlowEnabled,
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
      return this.licensedAiFeaturesAvailable && this.showDuoContextExclusion;
    },
    showCascadingButton() {
      return (
        this.duoFeaturesLocked &&
        this.cascadingSettingsData &&
        Object.keys(this.cascadingSettingsData).length
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
          v-if="showCascadingButton"
          data-testid="duo-cascading-lock-icon"
          :is-locked-by-group-ancestor="cascadingSettingsData.lockedByAncestor"
          :is-locked-by-application-settings="cascadingSettingsData.lockedByApplicationSetting"
          :ancestor-namespace="cascadingSettingsData.ancestorNamespace"
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
        class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5 gl-pl-5 md:gl-pl-7"
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
        class="project-feature-setting-group gl-flex gl-flex-col gl-gap-5 gl-pl-5 md:gl-pl-7"
      >
        <project-setting-row
          :label="s__('DuoAgentPlatform|Allow flow execution')"
          class="gl-mt-5"
          :help-text="
            s__('DuoAgentPlatform|Allow GitLab Duo agents to execute flows in this project.')
          "
        >
          <gl-toggle
            v-model="duoFlowEnabled"
            class="gl-mt-2"
            :disabled="duoFeaturesLocked || !duoEnabled"
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

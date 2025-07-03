<script>
import { GlCard, GlToggle, GlButton } from '@gitlab/ui';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, s__ } from '~/locale';
import { duoHelpPath, amazonQHelpPath } from '../constants';
import ProjectSettingRow from './project_setting_row.vue';

export default {
  i18n: {
    saveChanges: __('Save changes'),
  },
  name: 'GitlabDuoSettings',
  components: {
    GlCard,
    GlToggle,
    GlButton,
    ProjectSettingRow,
    CascadingLockIcon,
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
  },
  data() {
    return {
      autoReviewEnabled: this.amazonQAutoReviewEnabled,
      duoEnabled: this.duoFeaturesEnabled,
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
    showCascadingButton() {
      return (
        this.duoFeaturesLocked &&
        this.cascadingSettingsData &&
        Object.keys(this.cascadingSettingsData).length
      );
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
};
</script>

<template>
  <gl-card
    class="project-visibility-setting"
    body-class="gl-flex gl-flex-col gl-gap-6"
    data-testid="gitlab-duo-settings-card"
  >
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
            data-testid="amazon_q_auto_review_enabled"
          />
        </project-setting-row>
      </div>
    </project-setting-row>

    <template #footer>
      <gl-button
        variant="confirm"
        type="submit"
        data-testid="gitlab-duo-save-button"
        :disabled="duoFeaturesLocked"
      >
        {{ $options.i18n.saveChanges }}
      </gl-button>
    </template>
  </gl-card>
</template>

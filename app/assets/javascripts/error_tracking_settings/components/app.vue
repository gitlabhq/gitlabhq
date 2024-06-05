<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormCheckbox,
  GlFormRadioGroup,
  GlFormRadio,
  GlFormInputGroup,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import { I18N_ERROR_TRACKING_SETTINGS } from '../constants';
import ErrorTrackingForm from './error_tracking_form.vue';
import ProjectDropdown from './project_dropdown.vue';

export default {
  i18n: I18N_ERROR_TRACKING_SETTINGS,
  components: {
    ErrorTrackingForm,
    GlAlert,
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormRadioGroup,
    GlFormRadio,
    GlFormInputGroup,
    GlLink,
    GlSprintf,
    ProjectDropdown,
    ClipboardButton,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initialApiHost: {
      type: String,
      required: false,
      default: '',
    },
    initialEnabled: {
      type: String,
      required: true,
    },
    initialIntegrated: {
      type: String,
      required: true,
    },
    initialProject: {
      type: String,
      required: false,
      default: null,
    },
    initialToken: {
      type: String,
      required: false,
      default: '',
    },
    listProjectsEndpoint: {
      type: String,
      required: true,
    },
    operationsSettingsEndpoint: {
      type: String,
      required: true,
    },
    gitlabDsn: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isAlertDismissed: false,
    };
  },
  computed: {
    ...mapGetters([
      'dropdownLabel',
      'hasProjects',
      'invalidProjectLabel',
      'isProjectInvalid',
      'projectSelectionLabel',
    ]),
    ...mapState([
      'enabled',
      'integrated',
      'projects',
      'selectedProject',
      'settingsLoading',
      'token',
    ]),
    showGitlabDsnSetting() {
      return this.integrated && this.enabled && this.gitlabDsn;
    },
    showIntegratedErrorTracking() {
      return this.glFeatures.integratedErrorTracking === true;
    },
    setInitialEnabled() {
      if (this.showIntegratedErrorTracking) {
        return this.initialEnabled;
      }
      if (this.initialIntegrated === 'true') {
        return 'false';
      }
      return this.initialEnabled;
    },
    showIntegratedTrackingDisabledAlert() {
      return (
        !this.isAlertDismissed &&
        !this.showIntegratedErrorTracking &&
        this.initialIntegrated === 'true' &&
        this.initialEnabled === 'true'
      );
    },
  },
  epicLink: 'https://gitlab.com/gitlab-org/gitlab/-/issues/353639',
  featureFlagLink: helpPagePath('operations/error_tracking'),
  created() {
    this.setInitialState({
      apiHost: this.initialApiHost,
      enabled: this.setInitialEnabled,
      integrated: this.showIntegratedErrorTracking && this.initialIntegrated,
      project: this.initialProject,
      token: this.initialToken,
      listProjectsEndpoint: this.listProjectsEndpoint,
      operationsSettingsEndpoint: this.operationsSettingsEndpoint,
    });
  },
  methods: {
    ...mapActions([
      'setInitialState',
      'updateEnabled',
      'updateIntegrated',
      'updateSelectedProject',
      'updateSettings',
    ]),
    handleSubmit() {
      this.updateSettings();
    },
    dismissAlert() {
      this.isAlertDismissed = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showIntegratedTrackingDisabledAlert" variant="danger" @dismiss="dismissAlert">
      <gl-sprintf :message="$options.i18n.integratedErrorTrackingDisabledText">
        <template #epicLink="{ content }">
          <gl-link :href="$options.epicLink" target="_blank">{{ content }}</gl-link>
        </template>
        <template #flagLink="{ content }">
          <gl-link :href="$options.featureFlagLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-form-group
      :label="s__('ErrorTracking|Enable error tracking')"
      label-for="error-tracking-enabled"
    >
      <gl-form-checkbox
        id="error-tracking-enabled"
        :checked="enabled"
        data-testid="error-tracking-enabled"
        @change="updateEnabled"
      >
        {{ s__('ErrorTracking|Active') }}
      </gl-form-checkbox>
    </gl-form-group>
    <gl-form-group
      v-if="showIntegratedErrorTracking"
      :label="s__('ErrorTracking|Error tracking backend')"
      data-testid="tracking-backend-settings"
    >
      <gl-form-radio-group name="explicit" :checked="integrated" @change="updateIntegrated">
        <gl-form-radio name="error-tracking-integrated" :value="false">
          {{ __('Sentry') }}
          <template #help>
            {{ __('Requires you to deploy or set up cloud-hosted Sentry.') }}
          </template>
        </gl-form-radio>
        <gl-form-radio name="error-tracking-integrated" :value="true">
          {{ __('GitLab') }}
          <template #help>
            {{ __('Uses GitLab as an alternative to Sentry.') }}
          </template>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>
    <gl-form-group
      v-if="showGitlabDsnSetting"
      :label="__('Paste this Data Source Name (DSN) into your Sentry SDK.')"
      data-testid="gitlab-dsn-setting-form"
    >
      <gl-form-input-group readonly :value="gitlabDsn">
        <template #append>
          <clipboard-button :text="gitlabDsn" :title="__('Copy')" />
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <div v-if="!integrated" class="js-sentry-setting-form" data-testid="sentry-setting-form">
      <error-tracking-form />
      <div class="form-group">
        <project-dropdown
          :has-projects="hasProjects"
          :invalid-project-label="invalidProjectLabel"
          :is-project-invalid="isProjectInvalid"
          :dropdown-label="dropdownLabel"
          :project-selection-label="projectSelectionLabel"
          :projects="projects"
          :selected-project="selectedProject"
          :token="token"
          @select-project="updateSelectedProject"
        />
      </div>
    </div>
    <gl-button
      :disabled="settingsLoading"
      class="js-error-tracking-button"
      variant="confirm"
      @click="handleSubmit"
    >
      {{ __('Save changes') }}
    </gl-button>
  </div>
</template>

<script>
import { GlButton, GlFormGroup, GlFormCheckbox, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import ErrorTrackingForm from './error_tracking_form.vue';
import ProjectDropdown from './project_dropdown.vue';

export default {
  components: {
    ErrorTrackingForm,
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormRadioGroup,
    GlFormRadio,
    ProjectDropdown,
  },
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
  },
  created() {
    this.setInitialState({
      apiHost: this.initialApiHost,
      enabled: this.initialEnabled,
      integrated: this.initialIntegrated,
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
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="s__('ErrorTracking|Enable error tracking')"
      label-for="error-tracking-enabled"
    >
      <gl-form-checkbox id="error-tracking-enabled" :checked="enabled" @change="updateEnabled">
        {{ s__('ErrorTracking|Active') }}
      </gl-form-checkbox>
    </gl-form-group>
    <gl-form-group
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
            {{ __('Uses GitLab as a lightweight alternative to Sentry.') }}
          </template>
        </gl-form-radio>
      </gl-form-radio-group>
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

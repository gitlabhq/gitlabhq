<script>
import { GlButton, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import ErrorTrackingForm from './error_tracking_form.vue';
import ProjectDropdown from './project_dropdown.vue';

export default {
  components: {
    ErrorTrackingForm,
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
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
    ...mapState(['enabled', 'projects', 'selectedProject', 'settingsLoading', 'token']),
  },
  created() {
    this.setInitialState({
      apiHost: this.initialApiHost,
      enabled: this.initialEnabled,
      project: this.initialProject,
      token: this.initialToken,
      listProjectsEndpoint: this.listProjectsEndpoint,
      operationsSettingsEndpoint: this.operationsSettingsEndpoint,
    });
  },
  methods: {
    ...mapActions(['setInitialState', 'updateEnabled', 'updateSelectedProject', 'updateSettings']),
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
      <gl-form-checkbox
        id="error-tracking-enabled"
        :checked="enabled"
        @change="updateEnabled($event)"
      >
        {{ s__('ErrorTracking|Active') }}
      </gl-form-checkbox>
    </gl-form-group>
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

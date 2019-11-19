<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlButton } from '@gitlab/ui';
import ProjectDropdown from './project_dropdown.vue';
import ErrorTrackingForm from './error_tracking_form.vue';

export default {
  components: { ProjectDropdown, ErrorTrackingForm, GlButton },
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
    <div class="form-check form-group">
      <input
        id="error-tracking-enabled"
        :checked="enabled"
        class="form-check-input"
        type="checkbox"
        @change="updateEnabled($event.target.checked)"
      />
      <label class="form-check-label" for="error-tracking-enabled">{{
        s__('ErrorTracking|Active')
      }}</label>
    </div>
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
      variant="success"
      @click="handleSubmit"
    >
      {{ __('Save changes') }}
    </gl-button>
  </div>
</template>

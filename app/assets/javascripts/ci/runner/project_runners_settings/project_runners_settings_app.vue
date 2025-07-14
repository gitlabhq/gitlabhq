<script>
import { GlButton, GlAlert } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';

export default {
  name: 'ProjectRunnersSettingsApp',
  components: {
    GlAlert,
    GlButton,
    CrudComponent,
    RegistrationDropdown,
    RunnersTabs,
  },
  props: {
    canCreateRunner: {
      type: Boolean,
      required: true,
    },
    allowRegistrationToken: {
      type: Boolean,
      required: true,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    newProjectRunnerPath: {
      type: String,
      required: false,
      default: null,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    instanceRunnersEnabled: {
      type: Boolean,
      required: true,
    },
    instanceRunnersDisabledAndUnoverridable: {
      type: Boolean,
      required: true,
    },
    instanceRunnersUpdatePath: {
      type: String,
      required: true,
    },
    instanceRunnersGroupSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
    groupName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      errors: [],
    };
  },
  methods: {
    onError({ message }) {
      if (this.errors.indexOf(message) === -1) {
        this.errors.push(message);
      }
    },
    onDismissError(message) {
      this.errors = this.errors.filter((m) => m !== message);
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-for="error in errors"
      :key="error"
      class="gl-mb-4"
      variant="danger"
      @dismiss="onDismissError(error)"
    >
      {{ error }}
    </gl-alert>
    <crud-component :title="s__('Runners|Available Runners')" body-class="!gl-m-0">
      <template #actions>
        <gl-button v-if="canCreateRunner" size="small" :href="newProjectRunnerPath">{{
          s__('Runners|Create project runner')
        }}</gl-button>
        <registration-dropdown
          size="small"
          type="PROJECT_TYPE"
          :allow-registration-token="allowRegistrationToken"
          :registration-token="registrationToken"
        />
      </template>
      <runners-tabs
        :project-full-path="projectFullPath"
        :instance-runners-enabled="instanceRunnersEnabled"
        :instance-runners-disabled-and-unoverridable="instanceRunnersDisabledAndUnoverridable"
        :instance-runners-update-path="instanceRunnersUpdatePath"
        :instance-runners-group-settings-path="instanceRunnersGroupSettingsPath"
        :group-name="groupName"
        @error="onError"
      />
    </crud-component>
  </div>
</template>

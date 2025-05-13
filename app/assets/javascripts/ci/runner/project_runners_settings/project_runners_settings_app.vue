<script>
import { GlButton, GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { I18N_FETCH_ERROR } from '~/ci/runner/constants';
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
  },
  data() {
    return {
      hasFetchError: false,
    };
  },
  methods: {
    onError(error) {
      this.hasFetchError = true;
      Sentry.captureException(error);
    },
    onDismissError() {
      this.hasFetchError = false;
    },
  },
  I18N_FETCH_ERROR,
};
</script>
<template>
  <div>
    <gl-alert v-if="hasFetchError" class="gl-mb-4" variant="danger" @dismiss="onDismissError">
      {{ $options.I18N_FETCH_ERROR }}
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
      <runners-tabs :project-full-path="projectFullPath" @error="onError" />
    </crud-component>
  </div>
</template>

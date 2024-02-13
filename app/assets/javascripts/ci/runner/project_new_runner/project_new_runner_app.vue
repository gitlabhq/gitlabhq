<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import RegistrationCompatibilityAlert from '~/ci/runner/components/registration/registration_compatibility_alert.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCloudConnectionForm from '~/ci/runner/components/runner_cloud_connection_form.vue';
import RunnerCloudExecutionEnvironment from '~/ci/runner/components/runner_cloud_execution_environment.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import {
  DEFAULT_PLATFORM,
  PARAM_KEY_PLATFORM,
  GOOGLE_CLOUD_PLATFORM,
  GOOGLE_CLOUD_SETUP_START,
  GOOGLE_CLOUD_SETUP_END,
  PROJECT_TYPE,
  I18N_CREATE_ERROR,
} from '../constants';
import { captureException } from '../sentry_utils';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'ProjectNewRunnerApp',
  components: {
    RegistrationCompatibilityAlert,
    RunnerPlatformsRadioGroup,
    RunnerCloudConnectionForm,
    RunnerCloudExecutionEnvironment,
    RunnerCreateForm,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    projectId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: DEFAULT_PLATFORM,
      googleCloudStage: GOOGLE_CLOUD_SETUP_START,
      cloudConnectionDetails: {},
    };
  },
  computed: {
    gcpEnabled() {
      return this.glFeatures.gcpRunner;
    },
    showCloudForm() {
      return (
        this.platform === GOOGLE_CLOUD_PLATFORM &&
        this.googleCloudStage === GOOGLE_CLOUD_SETUP_START &&
        this.gcpEnabled
      );
    },
    showCloudFormEnd() {
      return (
        this.platform === GOOGLE_CLOUD_PLATFORM &&
        this.googleCloudStage === GOOGLE_CLOUD_SETUP_END &&
        this.gcpEnabled
      );
    },
  },
  methods: {
    async createRunner(runnerInfo) {
      try {
        const {
          data: {
            runnerCreate: { errors, runner },
          },
        } = await this.$apollo.mutate({
          mutation: runnerCreateMutation,
          variables: {
            input: runnerInfo,
          },
        });

        if (errors?.length) {
          this.onError(new Error(errors.join(' ')), true);
          return;
        }

        if (!runner?.ephemeralRegisterUrl) {
          // runner is missing information, report issue and
          // fail naviation to register page.
          this.onError(new Error(I18N_CREATE_ERROR));
        }

        // TODO: Find out what we want to display
        // this.onSuccess(runner);
      } catch (error) {
        this.onError(error);
      }
    },
    onSaved(runner) {
      const params = { [PARAM_KEY_PLATFORM]: this.platform };
      const ephemeralRegisterUrl = setUrlParams(params, runner.ephemeralRegisterUrl);

      saveAlertToLocalStorage({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
      visitUrl(ephemeralRegisterUrl);
    },
    onError(error, isValidationError = false) {
      if (isValidationError) {
        captureException({ error, component: this.$options.name });
      }
      createAlert({ message: error.message });
    },
    onContinueGoogleCloud(cloudConnection) {
      // Store the variables from the start of the form
      this.cloudConnectionDetails = cloudConnection;
      this.googleCloudStage = GOOGLE_CLOUD_SETUP_END;
    },
    onPrevious() {
      this.googleCloudStage = GOOGLE_CLOUD_SETUP_START;
    },
  },
  PROJECT_TYPE,
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h2">{{ s__('Runners|New project runner') }}</h1>

    <registration-compatibility-alert :alert-key="projectId" />

    <p>
      {{
        s__(
          'Runners|Create a project runner to generate a command that registers the runner with all its configurations.',
        )
      }}
    </p>

    <hr aria-hidden="true" />

    <h2 class="gl-font-size-h2 gl-my-5">
      {{ s__('Runners|Platform') }}
    </h2>

    <runner-platforms-radio-group v-model="platform" />

    <hr aria-hidden="true" />

    <runner-cloud-connection-form v-if="showCloudForm" @continue="onContinueGoogleCloud" />

    <runner-cloud-execution-environment
      v-else-if="showCloudFormEnd"
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @submit="createRunner"
      @previous="onPrevious"
    />

    <runner-create-form
      v-else
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

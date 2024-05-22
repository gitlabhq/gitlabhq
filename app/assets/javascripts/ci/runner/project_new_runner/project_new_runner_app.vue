<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { DEFAULT_PLATFORM, GOOGLE_CLOUD_PLATFORM, PROJECT_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'ProjectNewRunnerApp',
  components: {
    RunnerCreateForm,
  },
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
  props: {
    projectId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: DEFAULT_PLATFORM,
    };
  },
  methods: {
    onSaved(runner) {
      this.trackEvent('click_create_project_runner_button');

      saveAlertToLocalStorage({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
      visitUrl(runner.ephemeralRegisterUrl);
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  PROJECT_TYPE,
  GOOGLE_CLOUD_PLATFORM,
};
</script>

<template>
  <div class="gl-mt-5">
    <h1 class="gl-heading-1">{{ s__('Runners|New project runner') }}</h1>

    <p>
      {{
        s__(
          'Runners|Create a project runner to generate a command that registers the runner with all its configurations.',
        )
      }}
    </p>

    <hr aria-hidden="true" />

    <runner-create-form
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { redirectTo, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { DEFAULT_PLATFORM, PARAM_KEY_PLATFORM, PROJECT_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'ProjectNewRunnerApp',
  components: {
    RunnerPlatformsRadioGroup,
    RunnerCreateForm,
  },
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
      const params = { [PARAM_KEY_PLATFORM]: this.platform };
      const ephemeralRegisterUrl = setUrlParams(params, runner.ephemeralRegisterUrl);

      saveAlertToLocalStorage({
        message: s__('Runners|Runner created.'),
        variant: VARIANT_SUCCESS,
      });
      redirectTo(ephemeralRegisterUrl);
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  PROJECT_TYPE,
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h2">{{ s__('Runners|New project runner') }}</h1>
    <p>
      {{
        s__(
          'Runners|Create a project runner to generate a command that registers the runner with all its configurations.',
        )
      }}
    </p>

    <hr aria-hidden="true" />

    <h2 class="gl-font-weight-normal gl-font-lg gl-my-5">
      {{ s__('Runners|Platform') }}
    </h2>
    <runner-platforms-radio-group v-model="platform" />

    <hr aria-hidden="true" />

    <runner-create-form
      :runner-type="$options.PROJECT_TYPE"
      :project-id="projectId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

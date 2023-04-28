<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { redirectTo, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import RegistrationCompatibilityAlert from '~/ci/runner/components/registration/registration_compatibility_alert.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { DEFAULT_PLATFORM, GROUP_TYPE, PARAM_KEY_PLATFORM } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'GroupNewRunnerApp',
  components: {
    RegistrationCompatibilityAlert,
    RunnerPlatformsRadioGroup,
    RunnerCreateForm,
  },
  props: {
    groupId: {
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
  GROUP_TYPE,
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h2">{{ s__('Runners|New group runner') }}</h1>

    <registration-compatibility-alert :alert-key="groupId" />

    <p>
      {{
        s__(
          'Runners|Create a group runner to generate a command that registers the runner with all its configurations.',
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
      :runner-type="$options.GROUP_TYPE"
      :group-id="groupId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

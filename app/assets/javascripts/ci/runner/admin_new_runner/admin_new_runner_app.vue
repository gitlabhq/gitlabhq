<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { DEFAULT_PLATFORM, PARAM_KEY_PLATFORM, INSTANCE_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'AdminNewRunnerApp',
  components: {
    RunnerPlatformsRadioGroup,
    RunnerCreateForm,
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
      visitUrl(ephemeralRegisterUrl);
    },
    onError(error) {
      createAlert({ message: error.message });
    },
  },
  INSTANCE_TYPE,
};
</script>

<template>
  <div class="gl-mt-5">
    <h1 class="gl-heading-1">{{ s__('Runners|New instance runner') }}</h1>

    <p>
      {{
        s__(
          'Runners|Create an instance runner to generate a command that registers the runner with all its configurations.',
        )
      }}
    </p>

    <hr aria-hidden="true" />

    <h2 class="gl-heading-2">
      {{ s__('Runners|Platform') }}
    </h2>

    <runner-platforms-radio-group v-model="platform" />

    <hr aria-hidden="true" />

    <runner-create-form :runner-type="$options.INSTANCE_TYPE" @saved="onSaved" @error="onError" />
  </div>
</template>

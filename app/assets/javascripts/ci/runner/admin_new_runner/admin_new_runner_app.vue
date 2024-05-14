<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { INSTANCE_TYPE } from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'AdminNewRunnerApp',
  components: {
    RunnerCreateForm,
  },
  methods: {
    onSaved(runner) {
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

    <runner-create-form :runner-type="$options.INSTANCE_TYPE" @saved="onSaved" @error="onError" />
  </div>
</template>

<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerGoogleCloudOption from '~/ci/runner/components/runner_google_cloud_option.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import {
  DEFAULT_PLATFORM,
  GOOGLE_CLOUD_PLATFORM,
  GROUP_TYPE,
  PARAM_KEY_PLATFORM,
} from '../constants';
import { saveAlertToLocalStorage } from '../local_storage_alert/save_alert_to_local_storage';

export default {
  name: 'GroupNewRunnerApp',
  components: {
    RunnerGoogleCloudOption,
    RunnerPlatformsRadioGroup,
    RunnerCreateForm,
  },
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
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
  computed: {
    googleCloudProvisioningEnabled() {
      return this.glFeatures.googleCloudSupportFeatureFlag;
    },
  },
  methods: {
    onSaved(runner) {
      const params = { [PARAM_KEY_PLATFORM]: this.platform };
      const ephemeralRegisterUrl = setUrlParams(params, runner.ephemeralRegisterUrl);

      this.trackEvent('click_create_group_runner_button');
      if (this.platform === GOOGLE_CLOUD_PLATFORM) {
        this.trackEvent('provision_group_runner_on_google_cloud');
      }

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
  GROUP_TYPE,
};
</script>

<template>
  <div class="gl-mt-5">
    <h1 class="gl-heading-1">{{ s__('Runners|New group runner') }}</h1>

    <p>
      {{
        s__(
          'Runners|Create a group runner to generate a command that registers the runner with all its configurations.',
        )
      }}
    </p>

    <hr aria-hidden="true" />

    <h2 class="gl-heading-2">
      {{ s__('Runners|Platform') }}
    </h2>

    <runner-platforms-radio-group v-model="platform">
      <template v-if="googleCloudProvisioningEnabled" #cloud-options>
        <runner-google-cloud-option v-model="platform" />
      </template>
    </runner-platforms-radio-group>

    <hr aria-hidden="true" />

    <runner-create-form
      :runner-type="$options.GROUP_TYPE"
      :group-id="groupId"
      @saved="onSaved"
      @error="onError"
    />
  </div>
</template>

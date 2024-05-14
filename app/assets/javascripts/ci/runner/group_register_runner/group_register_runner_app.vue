<script>
import { GlButton } from '@gitlab/ui';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import { PARAM_KEY_PLATFORM, GOOGLE_CLOUD_PLATFORM, DEFAULT_PLATFORM } from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';

export default {
  name: 'GroupRegisterRunnerApp',
  components: {
    GlButton,
    RegistrationInstructions,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: getParameterByName(PARAM_KEY_PLATFORM) || DEFAULT_PLATFORM,
    };
  },
  watch: {
    platform(platform) {
      updateHistory({
        url: mergeUrlParams({ [PARAM_KEY_PLATFORM]: platform }, window.location.href),
      });
    },
  },
  methods: {
    onSelectPlatform(platform) {
      this.platform = platform;
    },
    onRunnerRegistered() {
      if (this.platform === GOOGLE_CLOUD_PLATFORM) {
        this.trackEvent('provision_group_runner_on_google_cloud');
      }
    },
  },
};
</script>
<template>
  <div>
    <registration-instructions
      :runner-id="runnerId"
      :group-path="groupPath"
      :platform="platform"
      @selectPlatform="onSelectPlatform"
      @runnerRegistered="onRunnerRegistered"
    >
      <template #runner-list-name>{{ s__('Runners|Group area › Runners') }}</template>
    </registration-instructions>

    <gl-button
      :href="runnersPath"
      variant="confirm"
      data-event-tracking="click_view_runners_button_in_new_group_runner_form"
    >
      {{ s__('Runners|View runners') }}
    </gl-button>
  </div>
</template>

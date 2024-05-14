<script>
import { GlButton } from '@gitlab/ui';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM } from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';

export default {
  name: 'AdminRegisterRunnerApp',
  components: {
    GlButton,
    RegistrationInstructions,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
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
  },
};
</script>
<template>
  <div>
    <registration-instructions
      :runner-id="runnerId"
      :platform="platform"
      @selectPlatform="onSelectPlatform"
    >
      <template #runner-list-name>{{ s__('Runners|Admin area › Runners') }}</template>
    </registration-instructions>

    <gl-button :href="runnersPath" variant="confirm">{{ s__('Runners|View runners') }}</gl-button>
  </div>
</template>

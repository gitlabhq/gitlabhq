<script>
import { GOOGLE_CLOUD_PLATFORM } from '../constants';
import RunnerPlatformsRadio from './runner_platforms_radio.vue';

export default {
  name: 'RunnerGoogleCloudOption',
  GOOGLE_CLOUD_PLATFORM,
  components: {
    RunnerPlatformsRadio,
  },
  model: {
    event: 'input',
    prop: 'checked',
  },
  props: {
    checked: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="gl-mt-3 gl-mb-6">
    <label>{{ s__('Runners|Cloud') }}</label>

    <div class="gl-display-flex gl-flex-wrap gl-gap-3">
      <runner-platforms-radio
        :checked="checked"
        :value="$options.GOOGLE_CLOUD_PLATFORM"
        @input="$emit('input', $event)"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        Google Cloud
        <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      </runner-platforms-radio>
    </div>
  </div>
</template>

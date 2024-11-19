<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { GOOGLE_CLOUD_PLATFORM, GOOGLE_KUBERNETES_ENGINE } from '../constants';
import RunnerPlatformsRadio from './runner_platforms_radio.vue';

export default {
  name: 'RunnerGoogleCloudOption',
  GOOGLE_CLOUD_PLATFORM,
  GOOGLE_KUBERNETES_ENGINE,
  components: {
    RunnerPlatformsRadio,
  },
  mixins: [glFeatureFlagsMixin()],
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
  <div class="gl-mb-6 gl-mt-3">
    <label>{{ s__('Runners|Cloud') }}</label>

    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <runner-platforms-radio
        :checked="checked"
        :value="$options.GOOGLE_CLOUD_PLATFORM"
        @input="$emit('input', $event)"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        Google Cloud
        <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      </runner-platforms-radio>
      <runner-platforms-radio
        :checked="checked"
        :value="$options.GOOGLE_KUBERNETES_ENGINE"
        @input="$emit('input', $event)"
      >
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        GKE
        <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      </runner-platforms-radio>
    </div>
  </div>
</template>

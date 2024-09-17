<script>
import DOCKER_LOGO_URL from '@gitlab/svgs/dist/illustrations/third-party-logos/ci_cd-template-logos/docker.png';
import LINUX_LOGO_URL from '@gitlab/svgs/dist/illustrations/third-party-logos/linux.svg?url';
import KUBERNETES_LOGO_URL from '@gitlab/svgs/dist/illustrations/logos/kubernetes.svg?url';
import { GlFormRadioGroup, GlIcon, GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  LINUX_PLATFORM,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
  DOCKER_HELP_URL,
  KUBERNETES_HELP_URL,
} from '../constants';

import RunnerPlatformsRadio from './runner_platforms_radio.vue';

export default {
  components: {
    GlFormRadioGroup,
    GlLink,
    GlIcon,
    RunnerPlatformsRadio,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      model: this.value,
    };
  },
  watch: {
    model() {
      this.$emit('input', this.model);
    },
  },
  LINUX_PLATFORM,
  LINUX_LOGO_URL,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
  DOCKER_HELP_URL,
  DOCKER_LOGO_URL,
  KUBERNETES_HELP_URL,
  KUBERNETES_LOGO_URL,
};
</script>

<template>
  <gl-form-radio-group v-model="model">
    <div class="gl-mb-6 gl-mt-3">
      <label>{{ s__('Runners|Operating systems') }}</label>

      <div class="gl-flex gl-flex-wrap gl-gap-3">
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <runner-platforms-radio
          v-model="model"
          :image="$options.LINUX_LOGO_URL"
          :value="$options.LINUX_PLATFORM"
        >
          Linux
        </runner-platforms-radio>
        <runner-platforms-radio v-model="model" :value="$options.MACOS_PLATFORM">
          macOS
        </runner-platforms-radio>
        <runner-platforms-radio v-model="model" :value="$options.WINDOWS_PLATFORM">
          Windows
        </runner-platforms-radio>
      </div>
    </div>

    <slot name="cloud-options"></slot>

    <div class="gl-mb-6 gl-mt-3">
      <label>{{ s__('Runners|Containers') }}</label>

      <div class="gl-flex gl-flex-wrap gl-gap-3">
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <runner-platforms-radio :image="$options.DOCKER_LOGO_URL">
          <gl-link :href="$options.DOCKER_HELP_URL" target="_blank">
            Docker
            <gl-icon name="external-link" />
          </gl-link>
        </runner-platforms-radio>
        <runner-platforms-radio :image="$options.KUBERNETES_LOGO_URL">
          <gl-link :href="$options.KUBERNETES_HELP_URL" target="_blank">
            Kubernetes
            <gl-icon name="external-link" />
          </gl-link>
        </runner-platforms-radio>
      </div>
    </div>
  </gl-form-radio-group>
</template>

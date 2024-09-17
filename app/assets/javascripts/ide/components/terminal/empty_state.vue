<script>
import { GlLoadingIcon, GlButton, GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    GlLoadingIcon,
    GlButton,
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
    isValid: {
      type: Boolean,
      required: false,
      default: false,
    },
    message: {
      type: String,
      required: false,
      default: '',
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    illustrationPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    onStart() {
      this.$emit('start');
    },
  },
};
</script>
<template>
  <div class="gl-p-5 gl-text-center">
    <div v-if="illustrationPath" class="svg-content svg-130"><img :src="illustrationPath" /></div>
    <h4>{{ __('Web Terminal') }}</h4>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />
    <template v-else>
      <p>{{ __('Run tests against your code live using the Web Terminal') }}</p>
      <p>
        <gl-button :disabled="!isValid" category="primary" variant="confirm" @click="onStart">
          {{ __('Start Web Terminal') }}
        </gl-button>
      </p>
      <gl-alert v-if="!isValid && message" variant="tip" :dismissible="false">
        <span v-safe-html="message"></span>
      </gl-alert>
      <p v-else>
        <a
          v-if="helpPath"
          :href="helpPath"
          target="_blank"
          v-text="__('Learn more about Web Terminal')"
        ></a>
      </p>
    </template>
  </div>
</template>

<script>
/* eslint-disable vue/no-v-html */
import { GlLoadingIcon, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
    GlButton,
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
  <div class="gl-text-center gl-p-5">
    <div v-if="illustrationPath" class="svg-content svg-130"><img :src="illustrationPath" /></div>
    <h4>{{ __('Web Terminal') }}</h4>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />
    <template v-else>
      <p>{{ __('Run tests against your code live using the Web Terminal') }}</p>
      <p>
        <gl-button
          :disabled="!isValid"
          category="primary"
          variant="info"
          data-qa-selector="start_web_terminal_button"
          @click="onStart"
        >
          {{ __('Start Web Terminal') }}
        </gl-button>
      </p>
      <div v-if="!isValid && message" class="bs-callout gl-text-left" v-html="message"></div>
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

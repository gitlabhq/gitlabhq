<script>
import { GlLoadingIcon } from '@gitlab/ui';
/* eslint-disable vue/require-default-prop */
/*
This component will be deprecated in favor of gl-deprecated-button.
https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-button--loading-button
https://gitlab.com/gitlab-org/gitlab/issues/207412
*/

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
    },
    containerClass: {
      type: [String, Array, Object],
      required: false,
      default: 'btn btn-align-content',
    },
  },
  methods: {
    onClick(e) {
      this.$emit('click', e);
    },
  },
};
</script>

<template>
  <button :class="containerClass" :disabled="loading || disabled" type="button" @click="onClick">
    <transition name="fade-in">
      <gl-loading-icon
        v-if="loading"
        :inline="true"
        :class="{
          'gl-mr-2': label,
        }"
        class="js-loading-button-icon"
      />
    </transition>
    <transition name="fade-in">
      <slot>
        <span v-if="label" class="js-loading-button-label"> {{ label }} </span>
      </slot>
    </transition>
  </button>
</template>

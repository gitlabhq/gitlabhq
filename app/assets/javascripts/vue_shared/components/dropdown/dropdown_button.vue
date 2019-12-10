<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    isDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    toggleText: {
      type: String,
      required: false,
      default: __('Select'),
    },
  },
};
</script>

<template>
  <button
    :disabled="isDisabled || isLoading"
    class="dropdown-menu-toggle dropdown-menu-full-width"
    type="button"
    data-toggle="dropdown"
    aria-expanded="false"
  >
    <gl-loading-icon v-show="isLoading" :inline="true" />
    <template>
      <slot v-if="$slots.default"></slot>
      <span v-else class="dropdown-toggle-text"> {{ toggleText }} </span>
    </template>
    <span v-show="!isLoading" class="dropdown-toggle-icon">
      <i class="fa fa-chevron-down" aria-hidden="true" data-hidden="true"></i>
    </span>
  </button>
</template>

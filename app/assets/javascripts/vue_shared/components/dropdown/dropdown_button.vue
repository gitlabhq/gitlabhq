<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
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
  <!-- eslint-disable @gitlab/vue-no-data-toggle -->
  <button
    :disabled="isDisabled || isLoading"
    class="dropdown-menu-toggle dropdown-menu-full-width"
    type="button"
    data-toggle="dropdown"
    aria-expanded="false"
  >
    <gl-loading-icon v-show="isLoading" size="sm" :inline="true" />
    <slot v-if="$slots.default"></slot>
    <span v-else class="dropdown-toggle-text"> {{ toggleText }} </span>
    <gl-icon
      v-show="!isLoading"
      class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
      name="chevron-down"
    />
  </button>
</template>

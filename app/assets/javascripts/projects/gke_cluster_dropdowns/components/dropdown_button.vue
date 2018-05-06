<script>
import { __ } from '~/locale';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

export default {
  components: {
    LoadingIcon,
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
      required: true,
      default: __('Select'),
    },
  },
};
</script>

<template>
  <button
    class="dropdown-menu-toggle dropdown-menu-full-width"
    type="button"
    data-toggle="dropdown"
    aria-expanded="true"
    :disabled="isDisabled || isLoading"
  >
    <loading-icon
      v-show="isLoading"
      :inline="true"
    />
    <span class="dropdown-toggle-text">
      {{ toggleText }}
    </span>
    <i
      aria-hidden="true"
      data-hidden="true"
      v-show="!isLoading"
      class="fa fa-chevron-down"
    ></i>
  </button>
</template>

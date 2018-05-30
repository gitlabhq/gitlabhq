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
      required: false,
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
    aria-expanded="false"
    :disabled="isDisabled || isLoading"
  >
    <loading-icon
      v-show="isLoading"
      :inline="true"
    />
    <span class="dropdown-toggle-text">
      {{ toggleText }}
    </span>
    <span
      class="dropdown-toggle-icon"
      v-show="!isLoading"
    >
      <i
        class="fa fa-chevron-down"
        aria-hidden="true"
        data-hidden="true"
      ></i>
    </span>
  </button>
</template>

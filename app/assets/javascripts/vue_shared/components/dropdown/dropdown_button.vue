<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'DropdownButton',
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  mixins: [glSlotsMixin],
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
    <slot v-if="glSlots().default"></slot>
    <span v-else class="dropdown-toggle-text"> {{ toggleText }} </span>
    <gl-icon
      v-show="!isLoading"
      class="gl-absolute gl-right-3 gl-top-3"
      name="chevron-down"
      variant="subtle"
    />
  </button>
</template>

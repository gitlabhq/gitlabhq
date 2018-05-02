<script>
import { __ } from '~/locale';
/**
 * Port of detail_behavior expand button.
 *
 * @example
 * <expand-button>
 *   <template slot="expanded">
 *      Text goes here.
 *    </template>
 * </expand-button>
 */
export default {
  name: 'ExpandButton',
  data() {
    return {
      isCollapsed: true,
    };
  },
  computed: {
    ariaLabel() {
      return __('Click to expand text');
    },
  },
  methods: {
    onClick() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>
<template>
  <span>
    <button
      type="button"
      v-show="isCollapsed"
      class="text-expander btn-blank"
      :aria-label="ariaLabel"
      @click="onClick">
      ...
    </button>
    <span v-if="!isCollapsed">
      <slot name="expanded"></slot>
    </span>
  </span>
</template>

<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

/**
 * Port of detail_behavior expand button.
 *
 * @example
 * <expand-button>
 *   <template #expanded>
 *      Text goes here.
 *    </template>
 * </expand-button>
 */
export default {
  name: 'ExpandButton',
  components: {
    GlButton,
  },
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
  destroyed() {
    this.isCollapsed = true;
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
    <gl-button
      v-show="isCollapsed"
      :aria-label="ariaLabel"
      type="button"
      class="js-text-expander-prepend text-expander btn-blank"
      icon="ellipsis_h"
      @click="onClick"
    />
    <span v-if="isCollapsed"> <slot name="short"></slot> </span>
    <span v-if="!isCollapsed"> <slot name="expanded"></slot> </span>
    <gl-button
      v-show="!isCollapsed"
      :aria-label="ariaLabel"
      type="button"
      class="js-text-expander-append text-expander btn-blank"
      icon="ellipsis_h"
      @click="onClick"
    />
  </span>
</template>

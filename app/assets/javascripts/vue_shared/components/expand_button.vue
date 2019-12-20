<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

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
  components: {
    GlButton,
    Icon,
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
      @click="onClick"
    >
      <icon :size="12" name="ellipsis_h" />
    </gl-button>
    <span v-if="isCollapsed"> <slot name="short"></slot> </span>
    <span v-if="!isCollapsed"> <slot name="expanded"></slot> </span>
    <gl-button
      v-show="!isCollapsed"
      :aria-label="ariaLabel"
      type="button"
      class="js-text-expander-append text-expander btn-blank"
      @click="onClick"
    >
      <icon :size="12" name="ellipsis_h" />
    </gl-button>
  </span>
</template>

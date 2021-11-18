<script>
import { GlBadge, GlTooltipDirective, GlResizeObserverDirective } from '@gitlab/ui';
import { RUNNER_TAG_BADGE_VARIANT } from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    tag: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: 'sm',
    },
  },
  data() {
    return {
      overflowing: false,
    };
  },
  computed: {
    tooltip() {
      if (this.overflowing) {
        return this.tag;
      }
      return '';
    },
  },
  methods: {
    onResize() {
      const { scrollWidth, offsetWidth } = this.$el;
      this.overflowing = scrollWidth > offsetWidth;
    },
  },
  RUNNER_TAG_BADGE_VARIANT,
};
</script>
<template>
  <gl-badge
    v-gl-tooltip="tooltip"
    v-gl-resize-observer="onResize"
    class="gl-display-inline-block gl-max-w-full gl-text-truncate"
    :size="size"
    :variant="$options.RUNNER_TAG_BADGE_VARIANT"
  >
    {{ tag }}
  </gl-badge>
</template>

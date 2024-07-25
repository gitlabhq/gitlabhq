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
    onResize({ target }) {
      const { scrollWidth, offsetWidth } = target;
      this.overflowing = scrollWidth > offsetWidth;
    },
  },
  RUNNER_TAG_BADGE_VARIANT,
};
</script>
<template>
  <gl-badge
    v-gl-tooltip="tooltip"
    class="gl-inline-block gl-overflow-hidden"
    :variant="$options.RUNNER_TAG_BADGE_VARIANT"
  >
    <span v-gl-resize-observer="onResize" class="gl-truncate">
      {{ tag }}
    </span>
  </gl-badge>
</template>

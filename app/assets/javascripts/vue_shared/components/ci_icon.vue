<script>
import { GlIcon } from '@gitlab/ui';

/**
 * Renders CI icon based on API response shared between all places where it is used.
 *
 * Receives status object containing:
 * status: {
 *   group:"running" // used for CSS class
 *   icon: "icon_status_running" // used to render the icon
 * }
 *
 * Used in:
 * - Extended MR Popover
 * - Jobs show view header
 * - Jobs show view sidebar
 * - Jobs table
 * - Linked pipelines
 * - Pipeline graph
 * - Pipeline mini graph
 * - Pipeline show view badge
 * - Pipelines table Badge
 */

/*
 * These sizes are defined in gitlab-ui/src/scss/variables.scss
 * under '$gl-icon-sizes'
 */
const validSizes = [8, 12, 14, 16, 24, 32, 48, 72];

export default {
  components: {
    GlIcon,
  },
  props: {
    status: {
      type: Object,
      required: true,
    },
    size: {
      type: Number,
      required: false,
      default: 16,
      validator(value) {
        return validSizes.includes(value);
      },
    },
    isActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBorderless: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInteractive: {
      type: Boolean,
      required: false,
      default: false,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    wrapperStyleClasses() {
      const status = this.status.group;
      return `ci-status-icon ci-status-icon-${status} js-ci-status-icon-${status} gl-rounded-full gl-justify-content-center gl-line-height-0`;
    },
    icon() {
      return this.isBorderless ? `${this.status.icon}_borderless` : this.status.icon;
    },
  },
};
</script>
<template>
  <span
    :class="[
      wrapperStyleClasses,
      { interactive: isInteractive, active: isActive, borderless: isBorderless },
    ]"
    :style="{ height: `${size}px`, width: `${size}px` }"
    data-testid="ci-icon-wrapper"
  >
    <gl-icon :name="icon" :size="size" :class="cssClasses" :aria-label="status.icon" />
  </span>
</template>

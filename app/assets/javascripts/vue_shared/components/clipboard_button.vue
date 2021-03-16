<script>
/**
 * Falls back to the code used in `copy_to_clipboard.js`
 *
 * Renders a button with a clipboard icon that copies the content of `data-clipboard-text`
 * when clicked.
 *
 * @example
 * <clipboard-button
 *   title="Copy"
 *   text="Content to be copied"
 *    css-class="btn-transparent"
 * />
 */
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'ClipboardButton',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  props: {
    text: {
      type: String,
      required: true,
    },
    gfm: {
      type: String,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: true,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    tooltipContainer: {
      type: [String, Boolean],
      required: false,
      default: false,
    },
    tooltipBoundary: {
      type: String,
      required: false,
      default: null,
    },
    cssClass: {
      type: String,
      required: false,
      default: null,
    },
    category: {
      type: String,
      required: false,
      default: 'secondary',
    },
    size: {
      type: String,
      required: false,
      default: 'medium',
    },
  },
  computed: {
    clipboardText() {
      if (this.gfm !== null) {
        return JSON.stringify({ text: this.text, gfm: this.gfm });
      }
      return this.text;
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover.blur.viewport="{
      placement: tooltipPlacement,
      container: tooltipContainer,
      boundary: tooltipBoundary,
    }"
    :class="cssClass"
    :title="title"
    :data-clipboard-text="clipboardText"
    :category="category"
    :size="size"
    icon="copy-to-clipboard"
    :aria-label="__('Copy this value')"
    v-on="$listeners"
  >
    <slot></slot>
  </gl-button>
</template>

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
import { GlDeprecatedButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';

export default {
  name: 'ClipboardButton',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDeprecatedButton,
    GlIcon,
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
    cssClass: {
      type: String,
      required: false,
      default: 'btn-default',
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
  <gl-deprecated-button
    v-gl-tooltip="{ placement: tooltipPlacement, container: tooltipContainer }"
    v-gl-tooltip.hover.blur
    :class="cssClass"
    :title="title"
    :data-clipboard-text="clipboardText"
  >
    <gl-icon name="copy-to-clipboard" />
  </gl-deprecated-button>
</template>

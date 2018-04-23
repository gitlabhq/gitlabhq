<script>
/**
 * Falls back to the code used in `copy_to_clipboard.js`
 *
 * Renders a button with a clipboard icon that copies the content of `data-clipboard-text`
 * when clicked.
 *
 * @example
 * <clipboard-button
 *   title="Copy to clipbard"
 *   text="Content to be copied"
 *    css-class="btn-transparent"
 * />
 */
import tooltip from '../directives/tooltip';

export default {
  name: 'ClipboardButton',
  directives: {
    tooltip,
  },
  props: {
    text: {
      type: String,
      required: true,
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
      default: 'btn-secondary',
    },
  },
};
</script>

<template>
  <button
    type="button"
    class="btn"
    :class="cssClass"
    :title="title"
    :data-clipboard-text="text"
    v-tooltip
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
  >
    <i
      aria-hidden="true"
      class="fa fa-clipboard"
    >
    </i>
  </button>
</template>

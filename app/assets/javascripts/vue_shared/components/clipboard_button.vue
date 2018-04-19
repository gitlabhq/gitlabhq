<script>
/**
 * Falls back to the code used in `copy_to_clipboard.js`
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
      default: 'btn-default',
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

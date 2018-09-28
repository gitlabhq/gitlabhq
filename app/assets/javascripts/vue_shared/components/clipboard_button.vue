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
import Icon from '../components/icon.vue';

export default {
  name: 'ClipboardButton',

  directives: {
    tooltip,
  },

  components: {
    Icon,
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
  <button
    v-tooltip
    :class="cssClass"
    :title="title"
    :data-clipboard-text="clipboardText"
    :data-container="tooltipContainer"
    :data-placement="tooltipPlacement"
    type="button"
    class="btn"
  >
    <icon name="duplicate" />
  </button>
</template>

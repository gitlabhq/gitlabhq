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
 *   css-class="gl-border-0 gl-bg-transparent"
 * />
 */
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { sanitize } from '~/lib/dompurify';

import { __ } from '~/locale';
import {
  CLIPBOARD_SUCCESS_EVENT,
  CLIPBOARD_ERROR_EVENT,
  I18N_ERROR_MESSAGE,
} from '~/behaviors/copy_to_clipboard';

export default {
  name: 'ClipboardButton',
  i18n: {
    copied: __('Copied'),
    error: I18N_ERROR_MESSAGE,
  },
  CLIPBOARD_SUCCESS_EVENT,
  CLIPBOARD_ERROR_EVENT,
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
    variant: {
      type: String,
      required: false,
      default: 'default',
    },
  },
  data() {
    return {
      localTitle: this.title,
      titleTimeout: null,
      id: null,
    };
  },
  computed: {
    clipboardText() {
      if (this.gfm !== null) {
        return JSON.stringify({ text: this.text, gfm: this.gfm });
      }
      return this.text;
    },
    tooltipDirectiveOptions() {
      return {
        placement: this.tooltipPlacement,
        container: this.tooltipContainer,
        boundary: this.tooltipBoundary,
      };
    },
    sanitizedLocalTitle() {
      return sanitize(this.localTitle);
    },
  },
  created() {
    this.id = uniqueId('clipboard-button-');
  },
  methods: {
    updateTooltip(title) {
      this.localTitle = title;
      this.$root.$emit('bv::show::tooltip', this.id);

      clearTimeout(this.titleTimeout);

      this.titleTimeout = setTimeout(() => {
        this.localTitle = this.title;
        this.$root.$emit('bv::hide::tooltip', this.id);
      }, 1000);
    },
  },
};
</script>

<template>
  <gl-button
    :id="id"
    ref="copyButton"
    v-gl-tooltip.hover.focus.click.viewport.html="tooltipDirectiveOptions"
    :class="cssClass"
    :title="sanitizedLocalTitle"
    :data-clipboard-text="clipboardText"
    data-clipboard-handle-tooltip="false"
    :category="category"
    :size="size"
    icon="copy-to-clipboard"
    :variant="variant"
    :aria-label="sanitizedLocalTitle"
    aria-live="polite"
    @[$options.CLIPBOARD_SUCCESS_EVENT]="updateTooltip($options.i18n.copied)"
    @[$options.CLIPBOARD_ERROR_EVENT]="updateTooltip($options.i18n.error)"
    v-on="$listeners"
  >
    <slot></slot>
  </gl-button>
</template>

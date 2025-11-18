<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

/**
 * Button that programmatically copies text to the clipboard upon click. Attempts
 * to copy in both secure and non-secure contexts.
 *
 * It is meant to supersede `<modal-copy-button>` and `<clipboard-button>`, should work
 * in modals and it does not have a ClipboardJS dependency.
 *
 * By default, shows a toast (where available) when contents are copied successfully.
 *
 * @example
 *
 * <simple-copy-button
 *   title="Copy URL"
 *   text="http://example.com"
 *   toast-message="URL copied to clipboard."
 * />
 *
 * Other customization options:
 *
 * <simple-copy-button
 *   title="Copy another URL"
 *   text="http://another.example.com"
 *   class="custom-class-1 custom-class-2"
 *   variant="confirm"
 *   :toast-message="false" # Skip success toast message if you want your own handling at `@copied`
 *   @copied="onCopied"
 *   @error="onError" # Rare, but can happen
 * />
 *
 * See: https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts
 */

export default {
  name: 'SimpleCopyButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    id: {
      type: String,
      required: false,
      default: () => uniqueId('clipboard-button-'),
    },
    text: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: __('Copy'),
    },
    toastMessage: {
      type: [String, Boolean],
      required: false,
      default: __('Copied to clipboard.'),
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    tooltipContainer: {
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
    icon: {
      type: String,
      required: false,
      default: 'copy-to-clipboard',
    },
  },
  emits: ['copied', 'error'],
  methods: {
    async onClick() {
      try {
        await copyToClipboard(this.text, this.$el);

        if (typeof this.toastMessage === 'string' && this.toastMessage) {
          this.$toast?.show(this.toastMessage);
        }
        this.$emit('copied');
      } catch (e) {
        this.$emit('error', e);
        Sentry.captureException(e);
      }
    },
    onMouseout() {
      // Tooltip still appears after clicking focusing on the button, ensure it's hidden
      this.$root.$emit('bv::hide::tooltip', this.id);
    },
  },
};
</script>
<template>
  <gl-button
    :id="id"
    v-gl-tooltip="{
      title,
      placement: tooltipPlacement,
      container: tooltipContainer,
    }"
    aria-live="polite"
    :aria-label="$attrs.ariaLabel || title"
    :category="category"
    :size="size"
    :icon="icon"
    :variant="variant"
    @click="onClick"
    @mouseout="onMouseout"
  />
</template>

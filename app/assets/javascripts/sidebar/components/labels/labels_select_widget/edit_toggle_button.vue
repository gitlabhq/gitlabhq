<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { keysFor, ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import { keyboardShortcutsDisabled } from '~/behaviors/shortcuts/shortcuts_disabled';
import { sanitize } from '~/lib/dompurify';

export default {
  name: 'EditToggleButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    accessibilityAttributes: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shortcutDescription() {
      return keyboardShortcutsDisabled() ? null : ISSUABLE_CHANGE_LABEL.description;
    },
    shortcutKey() {
      return keyboardShortcutsDisabled() ? null : keysFor(ISSUABLE_CHANGE_LABEL)[0];
    },
    tooltip() {
      return keyboardShortcutsDisabled()
        ? null
        : sanitize(
            `${this.shortcutDescription} <kbd class="flat gl-ml-1" aria-hidden=true>${this.shortcutKey}</kbd>`,
          );
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.viewport.html
    v-bind="accessibilityAttributes"
    class="shortcut-sidebar-dropdown-toggle"
    category="tertiary"
    size="small"
    :loading="loading"
    :title="tooltip"
    :aria-label="shortcutDescription"
    :aria-keyshortcuts="shortcutKey"
    data-testid="labels-edit"
    >{{ __('Edit') }}</gl-button
  >
</template>

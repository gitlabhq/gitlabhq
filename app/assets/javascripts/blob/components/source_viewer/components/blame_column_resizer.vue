<script>
import AccessorUtilities from '~/lib/utils/accessor';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { __ } from '~/locale';
import AccessiblePanelResizer from '~/vue_shared/components/accessible_panel_resizer.vue';
import {
  BLAME_COLUMN_DEFAULT_WIDTH,
  BLAME_COLUMN_MAX_WIDTH,
  BLAME_COLUMN_MIN_WIDTH,
  BLAME_COLUMN_WIDTH_STORAGE_KEY,
} from '../constants';

/**
 * Owns the width of the blame column: the drag handle, the persisted user
 * preference, and the breakpoint behaviour. The caller keeps the resulting width
 * (via `v-model`) because only the caller knows how to apply it — the chunked
 * viewer feeds it to a grid track, while the simple viewer sets a container
 * width. The handle positions itself against the nearest positioned ancestor, so
 * the caller is responsible for providing one that matches the column.
 */
export default {
  name: 'BlameColumnResizer',
  components: {
    AccessiblePanelResizer,
  },
  i18n: {
    resizeLabel: __('Resize blame column'),
  },
  widths: {
    default: BLAME_COLUMN_DEFAULT_WIDTH,
    max: BLAME_COLUMN_MAX_WIDTH,
    min: BLAME_COLUMN_MIN_WIDTH,
  },
  storageKey: BLAME_COLUMN_WIDTH_STORAGE_KEY,
  props: {
    value: {
      type: Number,
      required: false,
      default: BLAME_COLUMN_DEFAULT_WIDTH,
    },
  },
  emits: ['input'],
  data() {
    return {
      isDesktop: PanelBreakpointInstance.isDesktop(),
    };
  },
  mounted() {
    PanelBreakpointInstance.addResizeListener(this.handlePanelResize);
    this.restoreWidth();
  },
  beforeDestroy() {
    PanelBreakpointInstance.removeResizeListener(this.handlePanelResize);
  },
  methods: {
    handlePanelResize() {
      this.isDesktop = PanelBreakpointInstance.isDesktop();
      this.restoreWidth();
    },
    restoreWidth() {
      if (!this.isDesktop) {
        this.$emit('input', this.$options.widths.min);
        return;
      }

      // Without storage there is no preference to restore, so the current width
      // stands rather than being reset.
      if (!AccessorUtilities.canUseLocalStorage()) return;

      const userPreference = localStorage.getItem(this.$options.storageKey);
      this.$emit('input', parseInt(userPreference, 10) || this.$options.widths.default);
    },
    onResize(width) {
      this.$emit('input', width ?? this.$options.widths.default);
    },
    onResizeEnd(width) {
      if (!AccessorUtilities.canUseLocalStorage()) return;
      localStorage.setItem(this.$options.storageKey, width);
    },
  },
};
</script>

<template>
  <accessible-panel-resizer
    v-if="isDesktop"
    side="right"
    custom-class="gl-pointer-events-auto"
    :aria-label="$options.i18n.resizeLabel"
    :value="value"
    :default-size="$options.widths.default"
    :min-size="$options.widths.min"
    :max-size="$options.widths.max"
    @input="onResize"
    @resize-end="onResizeEnd"
  />
</template>

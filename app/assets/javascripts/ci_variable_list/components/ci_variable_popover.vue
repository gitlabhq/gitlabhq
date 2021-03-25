<script>
import { GlPopover, GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  maxTextLength: 95,
  components: {
    GlPopover,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    target: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
    tooltipText: {
      type: String,
      required: true,
    },
  },
  computed: {
    displayValue() {
      if (this.value.length > this.$options.maxTextLength) {
        return `${this.value.substring(0, this.$options.maxTextLength)}...`;
      }
      return this.value;
    },
  },
};
</script>

<template>
  <div id="popover-container">
    <gl-popover :target="target" placement="top" container="popover-container">
      <div
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-word-break-all"
      >
        <div class="ci-popover-value gl-pr-3">
          {{ displayValue }}
        </div>
        <gl-button
          v-gl-tooltip
          category="tertiary"
          icon="copy-to-clipboard"
          :title="tooltipText"
          :data-clipboard-text="value"
          :aria-label="__('Copy to clipboard')"
        />
      </div>
    </gl-popover>
  </div>
</template>

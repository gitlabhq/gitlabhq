<script>
import { GlPopover, GlIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  maxTextLength: 95,
  components: {
    GlPopover,
    GlIcon,
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
    <gl-popover :target="target" triggers="hover" placement="top" container="popover-container">
      <div class="d-flex justify-content-between position-relative">
        <div class="pr-5 w-100 ci-popover-value">{{ displayValue }}</div>
        <gl-button
          v-gl-tooltip
          class="btn-transparent btn-clipboard position-absolute position-top-0 position-right-0"
          :title="tooltipText"
          :data-clipboard-text="value"
        >
          <gl-icon name="copy-to-clipboard" />
        </gl-button>
      </div>
    </gl-popover>
  </div>
</template>

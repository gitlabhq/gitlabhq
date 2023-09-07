<script>
import { GlTooltipDirective, GlResizeObserverDirective } from '@gitlab/ui';
import { isFunction, debounce } from 'lodash';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';

const UPDATE_TOOLTIP_DEBOUNCED_WAIT_MS = 300;

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    placement: {
      type: String,
      required: false,
      default: 'top',
    },
    boundary: {
      type: String,
      required: false,
      default: '',
    },
    truncateTarget: {
      type: [String, Function],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      tooltipDisabled: true,
    };
  },
  computed: {
    classes() {
      if (this.tooltipDisabled) {
        return '';
      }
      return 'js-show-tooltip';
    },
    tooltip() {
      return {
        title: this.title,
        placement: this.placement,
        disabled: this.tooltipDisabled,
        // Only set the tooltip boundary if it's truthy
        ...(this.boundary && { boundary: this.boundary }),
      };
    },
  },
  watch: {
    title() {
      // Wait on $nextTick in case the slot width changes
      this.$nextTick(this.updateTooltip);
    },
  },
  created() {
    this.updateTooltipDebounced = debounce(this.updateTooltip, UPDATE_TOOLTIP_DEBOUNCED_WAIT_MS);
  },
  mounted() {
    this.updateTooltip();
  },
  methods: {
    selectTarget() {
      if (isFunction(this.truncateTarget)) {
        return this.truncateTarget(this.$el);
      }
      if (this.truncateTarget === 'child') {
        return this.$el.childNodes[0];
      }
      return this.$el;
    },
    updateTooltip() {
      this.tooltipDisabled = !hasHorizontalOverflow(this.selectTarget());
    },
    onResize() {
      this.updateTooltipDebounced();
    },
  },
};
</script>

<template>
  <span v-gl-tooltip="tooltip" v-gl-resize-observer="onResize" :class="classes" class="gl-min-w-0">
    <slot></slot>
  </span>
</template>

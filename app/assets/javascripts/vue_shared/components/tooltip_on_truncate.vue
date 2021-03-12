<script>
import { GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { isFunction } from 'lodash';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';

export default {
  directives: {
    GlTooltip,
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
    truncateTarget: {
      type: [String, Function],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showTooltip: false,
    };
  },
  watch: {
    title() {
      // Wait on $nextTick in case of slot width changes
      this.$nextTick(this.updateTooltip);
    },
  },
  mounted() {
    this.updateTooltip();
  },
  methods: {
    selectTarget() {
      if (isFunction(this.truncateTarget)) {
        return this.truncateTarget(this.$el);
      } else if (this.truncateTarget === 'child') {
        return this.$el.childNodes[0];
      }

      return this.$el;
    },
    updateTooltip() {
      const target = this.selectTarget();
      this.showTooltip = hasHorizontalOverflow(target);
    },
  },
};
</script>

<template>
  <span
    v-if="showTooltip"
    v-gl-tooltip="{ placement }"
    :title="title"
    class="js-show-tooltip gl-min-w-0"
  >
    <slot></slot>
  </span>
  <span v-else class="gl-min-w-0"> <slot></slot> </span>
</template>

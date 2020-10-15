<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'CollapsedCalendarIcon',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    containerClass: {
      type: String,
      required: false,
      default: '',
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    click() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <div v-gl-tooltip.left.viewport :class="containerClass" :title="tooltipText" @click="click">
    <gl-icon v-if="showIcon" name="calendar" />
    <slot>
      <span> {{ text }} </span>
    </slot>
  </div>
</template>

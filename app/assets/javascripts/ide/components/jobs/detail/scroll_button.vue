<script>
import { GlIcon, GlTooltipDirective, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

const directions = {
  up: 'up',
  down: 'down',
};

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    direction: {
      type: String,
      required: true,
      validator(value) {
        return Object.keys(directions).includes(value);
      },
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tooltipTitle() {
      return this.direction === directions.up ? __('Scroll to top') : __('Scroll to bottom');
    },
    iconName() {
      return `scroll_${this.direction}`;
    },
  },
  methods: {
    clickedScroll() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip
    :title="tooltipTitle"
    class="controllers-buttons"
    data-container="body"
    data-placement="top"
  >
    <gl-button
      :disabled="disabled"
      class="!gl-m-0 gl-block !gl-min-w-0 gl-rounded-none !gl-border-0 !gl-border-none gl-bg-transparent !gl-p-0 !gl-shadow-none !gl-outline-none"
      type="button"
      :aria-label="tooltipTitle"
      @click="clickedScroll"
    >
      <gl-icon :name="iconName" />
    </gl-button>
  </div>
</template>

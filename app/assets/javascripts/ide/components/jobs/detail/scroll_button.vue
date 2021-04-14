<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '../../../../locale';

const directions = {
  up: 'up',
  down: 'down',
};

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
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
    <button
      :disabled="disabled"
      class="btn-scroll btn-transparent btn-blank"
      type="button"
      :aria-label="tooltipTitle"
      @click="clickedScroll"
    >
      <gl-icon :name="iconName" />
    </button>
  </div>
</template>

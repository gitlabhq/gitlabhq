<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: true,
    },
    iconClasses: {
      type: String,
      required: false,
      default: null,
    },
    showLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    tooltipTitle() {
      return this.showLabel ? '' : this.label;
    },
  },
  methods: {
    clicked() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <button
    v-gl-tooltip
    :aria-label="label"
    :title="tooltipTitle"
    type="button"
    class="btn-blank"
    @click.stop.prevent="clicked"
  >
    <gl-icon :name="icon" :class="iconClasses" />
    <template v-if="showLabel">
      {{ label }}
    </template>
  </button>
</template>

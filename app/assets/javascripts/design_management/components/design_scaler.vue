<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';

const SCALE_STEP_SIZE = 0.2;
const DEFAULT_SCALE = 1;
const MIN_SCALE = 1;
const MAX_SCALE = 2;

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  data() {
    return {
      scale: DEFAULT_SCALE,
    };
  },
  computed: {
    disableReset() {
      return this.scale <= MIN_SCALE;
    },
    disableDecrease() {
      return this.scale === DEFAULT_SCALE;
    },
    disableIncrease() {
      return this.scale >= MAX_SCALE;
    },
  },
  methods: {
    setScale(scale) {
      if (scale < MIN_SCALE) {
        return;
      }

      this.scale = Math.round(scale * 100) / 100;
      this.$emit('scale', this.scale);
    },
    incrementScale() {
      this.setScale(this.scale + SCALE_STEP_SIZE);
    },
    decrementScale() {
      this.setScale(this.scale - SCALE_STEP_SIZE);
    },
    resetScale() {
      this.setScale(DEFAULT_SCALE);
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-z-index-1">
    <gl-button
      icon="dash"
      :disabled="disableDecrease"
      :aria-label="__('Decrease')"
      @click="decrementScale"
    />
    <gl-button icon="redo" :disabled="disableReset" :aria-label="__('Reset')" @click="resetScale" />
    <gl-button
      icon="plus"
      :disabled="disableIncrease"
      :aria-label="__('Increase')"
      @click="incrementScale"
    />
  </gl-button-group>
</template>

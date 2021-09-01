<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';

const DEFAULT_SCALE = 1;
const MIN_SCALE = 1;
const ZOOM_LEVELS = 5;

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  props: {
    maxScale: {
      type: Number,
      required: true,
    },
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
      return this.scale >= this.maxScale;
    },
    stepSize() {
      return (this.maxScale - MIN_SCALE) / ZOOM_LEVELS;
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
      this.setScale(Math.min(this.scale + this.stepSize, this.maxScale));
    },
    decrementScale() {
      this.setScale(Math.max(this.scale - this.stepSize, MIN_SCALE));
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

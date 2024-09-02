<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

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
    disableDecrease() {
      return this.scale === MIN_SCALE;
    },
    disableIncrease() {
      return this.scale >= this.maxScale;
    },
    stepSize() {
      return (this.maxScale - MIN_SCALE) / ZOOM_LEVELS;
    },
    scaleLabel() {
      return sprintf(__(`%{scaleValue}%%`), { scaleValue: Math.ceil(this.scale * 100) });
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
      this.setScale(this.scale - this.stepSize);
    },
  },
};
</script>

<template>
  <gl-button-group class="gl-z-1">
    <gl-button
      icon="dash"
      :disabled="disableDecrease"
      :aria-label="__('Decrease')"
      @click="decrementScale"
    />
    <span data-testid="scale-value" class="gl-border-t gl-border-b gl-bg-white gl-p-3 gl-text-sm">{{
      scaleLabel
    }}</span>
    <gl-button
      icon="plus"
      :disabled="disableIncrease"
      :aria-label="__('Increase')"
      @click="incrementScale"
    />
  </gl-button-group>
</template>

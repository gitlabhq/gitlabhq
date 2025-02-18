<script>
import { SIDES, MAX_COMMIT_COUNT } from '../constants';

export default {
  props: {
    position: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
    maxCommits: {
      type: Number,
      required: true,
    },
  },
  computed: {
    label() {
      if (this.count >= MAX_COMMIT_COUNT) {
        return `${MAX_COMMIT_COUNT - 1}+`;
      }

      return this.count;
    },
    barGraphWidthFactor() {
      return this.maxCommits > 0 ? 100 / this.maxCommits : 0;
    },
    style() {
      return {
        width: `${this.count * this.barGraphWidthFactor}%`,
      };
    },
    isFullWidth() {
      return this.position === SIDES.full;
    },
    isLeftSide() {
      return this.position === SIDES.left;
    },
    roundedClass() {
      if (this.isFullWidth) return 'rounded';

      return `rounded-${this.position}`;
    },
    textAlignmentClass() {
      if (this.isFullWidth) return 'text-center';

      return `text-${this.isLeftSide ? SIDES.right : SIDES.left}`;
    },
    positionSideClass() {
      return `position-${this.isLeftSide ? SIDES.right : SIDES.left}-0`;
    },
  },
};
</script>

<template>
  <div
    :class="{ full: isFullWidth }"
    class="graph-side gl-relative gl-float-left gl-h-full gl-pt-2"
  >
    <div
      :style="style"
      :class="[roundedClass, positionSideClass]"
      class="bar js-graph-bar gl-absolute"
    ></div>
    <span :class="textAlignmentClass" class="count js-graph-count gl-block gl-px-1 gl-pt-1">
      {{ label }}
    </span>
  </div>
</template>

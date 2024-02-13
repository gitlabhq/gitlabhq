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
    class="position-relative float-left pt-1 graph-side gl-h-full"
  >
    <div
      :style="style"
      :class="[roundedClass, positionSideClass]"
      class="position-absolute bar js-graph-bar"
    ></div>
    <span :class="textAlignmentClass" class="gl-display-block gl-pt-1 gl-px-1 count js-graph-count">
      {{ label }}
    </span>
  </div>
</template>

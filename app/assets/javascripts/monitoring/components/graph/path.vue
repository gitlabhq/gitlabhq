<script>
export default {
  props: {
    generatedLinePath: {
      type: String,
      required: true,
    },
    generatedAreaPath: {
      type: String,
      required: true,
    },
    lineStyle: {
      type: String,
      required: false,
      default: '',
    },
    lineColor: {
      type: String,
      required: true,
    },
    areaColor: {
      type: String,
      required: true,
    },
    currentCoordinates: {
      type: Object,
      required: false,
      default: () => ({ currentX: 0, currentY: 0 }),
    },
    showDot: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    strokeDashArray() {
      if (this.lineStyle === 'dashed') return '3, 1';
      if (this.lineStyle === 'dotted') return '1, 1';
      return null;
    },
  },
};
</script>
<template>
  <g transform="translate(-5, 20)">
    <circle
      v-if="showDot"
      :cx="currentCoordinates.currentX"
      :cy="currentCoordinates.currentY"
      :fill="lineColor"
      :stroke="lineColor"
      class="circle-path"
      r="3"
    />
    <path
      :d="generatedAreaPath"
      :fill="areaColor"
      class="metric-area"
    />
    <path
      :d="generatedLinePath"
      :stroke="lineColor"
      :stroke-dasharray="strokeDashArray"
      class="metric-line"
      fill="none"
      stroke-width="1"
    />
  </g>
</template>

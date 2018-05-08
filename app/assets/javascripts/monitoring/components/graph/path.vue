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
  <g>
    <path
      class="metric-area"
      :d="generatedAreaPath"
      :fill="areaColor"
      transform="translate(-5, 20)"
    />
    <path
      class="metric-line"
      :d="generatedLinePath"
      :stroke="lineColor"
      fill="none"
      stroke-width="1"
      :stroke-dasharray="strokeDashArray"
      transform="translate(-5, 20)"
    />
  </g>
</template>

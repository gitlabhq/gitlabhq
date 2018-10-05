<script>
const red50 = '#fef6f5';
const red400 = '#e05842';

export default {
  props: {
    operator: {
      type: String,
      required: true,
      validator: val => ['=', '<', '>'].includes(val),
    },
    threshold: {
      type: Number,
      required: true,
    },
    graphDrawData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    thresholdData() {
      if (!this.graphDrawData.xDom) {
        return [];
      }
      const [xMin, xMax] = this.graphDrawData.xDom;
      const [yMin, yMax] = this.graphDrawData.yDom;

      const outOfRange = (this.operator === '>' && this.threshold > yMax) ||
        (this.operator === '<' && this.threshold < yMin);

      if (outOfRange) {
        return [];
      }

      return [
        { time: xMin, value: this.threshold },
        { time: xMax, value: this.threshold },
      ];
    },
    linePath() {
      if (!this.graphDrawData.lineFunction) {
        return '';
      }
      return this.graphDrawData.lineFunction(this.thresholdData);
    },
    areaPath() {
      if (this.operator === '>') {
        if (!this.graphDrawData.areaAboveLine) {
          return '';
        }
        return this.graphDrawData.areaAboveLine(this.thresholdData);
      } else if (this.operator === '<') {
        if (!this.graphDrawData.areaBelowLine) {
          return '';
        }
        return this.graphDrawData.areaBelowLine(this.thresholdData);
      }
      return '';
    },
  },
  created() {
    this.red50 = red50;
    this.red400 = red400;
  },
};
</script>

<template>
  <g
    v-if="thresholdData.length"
    transform="translate(-5, 20)"
    class="js-threshold-lines"
  >
    <path
      v-if="areaPath"
      :d="areaPath"
      :fill="red50"
    />
    <path
      :d="linePath"
      fill="none"
      :stroke="red400"
      stroke-width="1"
      stroke-dasharray="solid"
    />
  </g>
</template>

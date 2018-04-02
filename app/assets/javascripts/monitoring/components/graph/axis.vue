<script>
import { convertToSentenceCase } from '~/lib/utils/text_utility';

export default {
  props: {
    graphWidth: {
      type: Number,
      required: true,
    },
    graphHeight: {
      type: Number,
      required: true,
    },
    margin: {
      type: Object,
      required: true,
    },
    measurements: {
      type: Object,
      required: true,
    },
    yAxisLabel: {
      type: String,
      required: true,
    },
    unitOfDisplay: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      yLabelWidth: 0,
      yLabelHeight: 0,
    };
  },
  computed: {
    textTransform() {
      const yCoordinate =
        (this.graphHeight -
          this.margin.top +
          this.measurements.axisLabelLineOffset) /
          2 || 0;

      return `translate(15, ${yCoordinate}) rotate(-90)`;
    },

    rectTransform() {
      const yCoordinate =
        (this.graphHeight -
          this.margin.top +
          this.measurements.axisLabelLineOffset) /
          2 +
          this.yLabelWidth / 2 || 0;

      return `translate(0, ${yCoordinate}) rotate(-90)`;
    },

    xPosition() {
      return (
        (this.graphWidth + this.measurements.axisLabelLineOffset) / 2 -
          this.margin.right || 0
      );
    },

    yPosition() {
      return (
        this.graphHeight -
          this.margin.top +
          this.measurements.axisLabelLineOffset || 0
      );
    },

    yAxisLabelSentenceCase() {
      return `${convertToSentenceCase(this.yAxisLabel)} (${this.unitOfDisplay})`;
    },
  },
  mounted() {
    this.$nextTick(() => {
      const bbox = this.$refs.ylabel.getBBox();
      this.yLabelWidth = bbox.width + 10; // Added some padding
      this.yLabelHeight = bbox.height + 5;
    });
  },
};
</script>
<template>
  <g class="axis-label-container">
    <line
      class="label-x-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
      :y1="yPosition"
      :x2="graphWidth + 20"
      :y2="yPosition"
    />
    <line
      class="label-y-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
      y1="0"
      :x2="10"
      :y2="yPosition"
    />
    <rect
      class="rect-axis-text"
      :transform="rectTransform"
      :width="yLabelWidth"
      :height="yLabelHeight"
    />
    <text
      class="label-axis-text y-label-text"
      text-anchor="middle"
      :transform="textTransform"
      ref="ylabel"
    >
      {{ yAxisLabelSentenceCase }}
    </text>
    <rect
      class="rect-axis-text"
      :x="xPosition + 60"
      :y="graphHeight - 80"
      width="35"
      height="50"
    />
    <text
      class="label-axis-text x-label-text"
      :x="xPosition + 60"
      :y="yPosition"
      dy=".35em"
    >
      Time
    </text>
  </g>
</template>

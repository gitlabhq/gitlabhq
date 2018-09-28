<script>
import { convertToSentenceCase } from '~/lib/utils/text_utility';
import { s__ } from '~/locale';

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

    timeString() {
      return s__('PrometheusDashboard|Time');
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
      :y1="yPosition"
      :x2="graphWidth + 20"
      :y2="yPosition"
      class="label-x-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
    />
    <line
      :x2="10"
      :y2="yPosition"
      class="label-y-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
      y1="0"
    />
    <rect
      :transform="rectTransform"
      :width="yLabelWidth"
      :height="yLabelHeight"
      class="rect-axis-text"
    />
    <text
      ref="ylabel"
      :transform="textTransform"
      class="label-axis-text y-label-text"
      text-anchor="middle"
    >
      {{ yAxisLabelSentenceCase }}
    </text>
    <rect
      :x="xPosition + 60"
      :y="graphHeight - 80"
      class="rect-axis-text"
      width="35"
      height="50"
    />
    <text
      :x="xPosition + 60"
      :y="yPosition"
      class="label-axis-text x-label-text"
      dy=".35em"
    >
      {{ timeString }}
    </text>
  </g>
</template>

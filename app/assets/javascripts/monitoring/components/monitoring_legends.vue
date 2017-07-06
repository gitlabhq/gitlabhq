<script>
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
      areaColorRgb: {
        type: String,
        required: true,
      },
      legendTitle: {
        type: String,
        required: true,
      },
      yAxisLabel: {
        type: String,
        required: true,
      },
      metricUsage: {
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
        const yCoordinate = (((this.graphHeight - this.margin.top)
                          + this.measurements.axisLabelLineOffset) / 2) || 0;

        return `translate(15, ${yCoordinate}) rotate(-90)`;
      },

      rectTransform() {
        const yCoordinate = ((this.graphHeight - this.margin.top) / 2)
                            + (this.yLabelWidth / 2) + 10 || 0;

        return `translate(0, ${yCoordinate}) rotate(-90)`;
      },

      xPosition() {
        return (((this.graphWidth + this.measurements.axisLabelLineOffset) / 2)
               - this.margin.right) || 0;
      },

      yPosition() {
        return ((this.graphHeight - this.margin.top) + this.measurements.axisLabelLineOffset) || 0;
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
  <g 
    class="axis-label-container">
    <line
      class="label-x-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
      :y1="yPosition"
      :x2="graphWidth + 20"
      :y2="yPosition">
    </line>
    <line
      class="label-y-axis-line"
      stroke="#000000"
      stroke-width="1"
      x1="10"
      y1="0"
      :x2="10"
      :y2="yPosition">
    </line>
    <rect
      class="rect-axis-text"
      :transform="rectTransform"
      :width="yLabelWidth"
      :height="yLabelHeight">
    </rect>
    <text 
      class="label-axis-text y-label-text"
      text-anchor="middle"
      :transform="textTransform"
      ref="ylabel">
      {{yAxisLabel}}
    </text>
    <rect
      class="rect-axis-text"
      :x="xPosition + 60"
      :y="graphHeight - 80"
      width="35"
      height="50">
    </rect>
    <text
      class="label-axis-text x-label-text"
      :x="xPosition + 60"
      :y="yPosition"
      dy=".35em">
      Time
    </text>
    <rect
      :fill="areaColorRgb"
      :width="measurements.legends.width"
      :height="measurements.legends.height"
      x="20"
      :y="graphHeight - measurements.legendOffset">
    </rect>
    <text
      class="text-metric-title"
      x="50"
      :y="graphHeight - 25">
      {{legendTitle}}
    </text>
    <text
      class="text-metric-usage"
      x="50"
      :y="graphHeight - 10">
      {{metricUsage}}
    </text>
  </g>
</template>

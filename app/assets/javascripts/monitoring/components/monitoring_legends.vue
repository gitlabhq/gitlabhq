<script>
  export default {
    props: {
      width: {
        type: Number,
        required: true,
      },
      height: {
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
    computed: {
      textTransform() {
        const yCoordinate = (((this.height - this.margin.top)
                          + this.measurements.axisLabelLineOffset) / 2) || 0;
        return `translate(15, ${yCoordinate}) rotate(-90)`;
      },

      xPosition() {
        return (((this.width + this.measurements.axisLabelLineOffset) / 2) - this.margin.right) || 0;
      },

      yPosition() {
        return ((this.height - this.margin.top) + this.measurements.axisLabelLineOffset) || 0;
      },
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
      :x2="width + 20"
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
      x="-10"
      y="50"
      :width="measurements.backgroundLegend.width"
      :height="measurements.backgroundLegend.height">
    </rect>
    <text 
      class="label-axis-text"
      text-anchor="middle"
      :transform="textTransform">
      {{yAxisLabel}}
    </text>
    <rect
      class="rect-axis-text"
      :x="xPosition"
      :y="height - 80"
      width="30"
      height="50">
    </rect>
    <text
      class="label-axis-text"
      :x="xPosition"
      :y="yPosition"
      dy=".35em">
      Time
    </text>
    <rect
      :fill="areaColorRgb"
      :width="measurements.legends.width"
      :height="measurements.legends.height"
      x="20"
      :y="height - measurements.legendOffset">
    </rect>
    <text
      class="text-metric-title"
      x="50"
      :y="height - 40">
      {{legendTitle}}
    </text>
    <text
      class="text-metric-usage"
      x="50"
      :y="height - 25">
      {{metricUsage}}
    </text>
  </g>
</template>

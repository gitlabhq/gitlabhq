<script>
  import {
      dateFormat,
      timeFormat,
    } from '../constants';

  export default {
    props: {
      currentXCoordinate: {
        type: Number,
        required: true,
      },
      currentYCoordinate: {
        type: Number,
        required: true,
      },
      currentFlagPosition: {
        type: Number,
        required: true,
      },
      currentData: {
        type: Object,
        required: true,
      },
      graphHeight: {
        type: Number,
        required: true,
      },
      graphHeightOffset: {
        type: Number,
        required: true,
      },
    },

    data() {
      return {
        circleColorRgb: '#8fbce8',
      };
    },

    computed: {
      formatTime() {
        return timeFormat(this.currentData.time);
      },

      formatDate() {
        return dateFormat(this.currentData.time);
      },

      calculatedHeight() {
        return this.graphHeight - this.graphHeightOffset;
      },
    },
  };
</script>
<template>
  <g class="mouse-over-flag">
    <line
      class="selected-metric-line"
      :x1="currentXCoordinate"
      :y1="0"
      :x2="currentXCoordinate"
      :y2="calculatedHeight"
      transform="translate(-5, 20)">
    </line>
    <circle
      class="circle-metric"
      :fill="circleColorRgb"
      stroke="#000"
      :cx="currentXCoordinate"
      :cy="currentYCoordinate"
      r="5"
      transform="translate(-5, 20)">
    </circle>
    <svg 
      class="rect-text-metric"
      :x="currentFlagPosition"
      y="0">
      <rect
        class="rect-metric"
        x="4"
        y="1"
        rx="2"
        width="90"
        height="40"
        transform="translate(-3, 20)">
      </rect>
      <text
        class="text-metric text-metric-bold"
        x="16"
        y="35"
        transform="translate(-5, 20)">
        {{formatTime}}
      </text>
      <text
        class="text-metric"
        x="16"
        y="15"
        transform="translate(-5, 20)">
        {{formatDate}}
      </text>
    </svg>
  </g>
</template>

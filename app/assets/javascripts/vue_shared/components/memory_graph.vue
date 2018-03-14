<script>
import { getTimeago } from '../../lib/utils/datetime_utility';

export default {
  name: 'MemoryGraph',
  props: {
    metrics: { type: Array, required: true },
    deploymentTime: { type: Number, required: true },
    width: { type: String, required: true },
    height: { type: String, required: true },
  },
  data() {
    return {
      pathD: '',
      pathViewBox: '',
      dotX: '',
      dotY: '',
    };
  },
  computed: {
    getFormattedMedian() {
      const deployedSince = getTimeago().format(this.deploymentTime * 1000);
      return `Deployed ${deployedSince}`;
    },
  },
  mounted() {
    this.renderGraph(this.deploymentTime, this.metrics);
  },
  methods: {
    /**
     * Returns metric value index in metrics array
     * with timestamp closest to matching median
     */
    getMedianMetricIndex(median, metrics) {
      let matchIndex = 0;
      let timestampDiff = 0;
      let smallestDiff = 0;

      const metricTimestamps = metrics.map(v => v[0]);

      // Find metric timestamp which is closest to deploymentTime
      timestampDiff = Math.abs(metricTimestamps[0] - median);
      metricTimestamps.forEach((timestamp, index) => {
        if (index === 0) { // Skip first element
          return;
        }

        smallestDiff = Math.abs(timestamp - median);
        if (smallestDiff < timestampDiff) {
          matchIndex = index;
          timestampDiff = smallestDiff;
        }
      });

      return matchIndex;
    },

    /**
     * Get Graph Plotting values to render Line and Dot
     */
    getGraphPlotValues(median, metrics) {
      const renderData = metrics.map(v => v[1]);
      const medianMetricIndex = this.getMedianMetricIndex(median, metrics);
      let cx = 0;
      let cy = 0;

      // Find Maximum and Minimum values from `renderData` array
      const maxMemory = Math.max.apply(null, renderData);
      const minMemory = Math.min.apply(null, renderData);

      // Find difference between extreme ends
      const diff = maxMemory - minMemory;
      const lineWidth = renderData.length;

      // Iterate over metrics values and perform following
      // 1. Find x & y co-ords for deploymentTime's memory value
      // 2. Return line path against maxMemory
      const linePath = renderData.map((y, x) => {
        if (medianMetricIndex === x) {
          cx = x;
          cy = maxMemory - y;
        }
        return `${x} ${maxMemory - y}`;
      });

      return {
        pathD: linePath,
        pathViewBox: {
          lineWidth,
          diff,
        },
        dotX: cx,
        dotY: cy,
      };
    },

    /**
     * Render Graph based on provided median and metrics values
     */
    renderGraph(median, metrics) {
      const { pathD, pathViewBox, dotX, dotY } = this.getGraphPlotValues(median, metrics);

      // Set props and update graph on UI.
      this.pathD = `M ${pathD}`;
      this.pathViewBox = `0 0 ${pathViewBox.lineWidth} ${pathViewBox.diff}`;
      this.dotX = dotX;
      this.dotY = dotY;
    },
  },
};
</script>

<template>
  <div class="memory-graph-container">
    <svg
      class="has-tooltip"
      :title="getFormattedMedian"
      :width="width"
      :height="height"
      xmlns="http://www.w3.org/2000/svg">
      <path
        :d="pathD"
        :viewBox="pathViewBox"
      />
      <circle
        r="1.5"
        :cx="dotX"
        :cy="dotY"
        tranform="translate(0 -1)"
      />
    </svg>
  </div>
</template>

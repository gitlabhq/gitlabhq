<script>
import { scaleLinear, scaleTime } from 'd3-scale';
import { axisLeft, axisBottom } from 'd3-axis';
import { max, extent } from 'd3-array';
import { select } from 'd3-selection';
import GraphAxis from './graph/axis.vue';
import GraphLegend from './graph/legend.vue';
import GraphFlag from './graph/flag.vue';
import GraphDeployment from './graph/deployment.vue';
import GraphPath from './graph/path.vue';
import MonitoringMixin from '../mixins/monitoring_mixins';
import eventHub from '../event_hub';
import measurements from '../utils/measurements';
import { bisectDate, timeScaleFormat } from '../utils/date_time_formatters';
import createTimeSeries from '../utils/multiple_time_series';
import bp from '../../breakpoints';

const d3 = { scaleLinear, scaleTime, axisLeft, axisBottom, max, extent, select };

export default {
  components: {
    GraphAxis,
    GraphFlag,
    GraphDeployment,
    GraphPath,
    GraphLegend,
  },
  mixins: [MonitoringMixin],
  props: {
    graphData: {
      type: Object,
      required: true,
    },
    updateAspectRatio: {
      type: Boolean,
      required: true,
    },
    deploymentData: {
      type: Array,
      required: true,
    },
    hoverData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectPath: {
      type: String,
      required: true,
    },
    tagsPath: {
      type: String,
      required: true,
    },
    showLegend: {
      type: Boolean,
      required: false,
      default: true,
    },
    smallGraph: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      baseGraphHeight: 450,
      baseGraphWidth: 600,
      graphHeight: 450,
      graphWidth: 600,
      graphHeightOffset: 120,
      margin: {},
      unitOfDisplay: '',
      yAxisLabel: '',
      legendTitle: '',
      reducedDeploymentData: [],
      measurements: measurements.large,
      currentData: {
        time: new Date(),
        value: 0,
      },
      currentDataIndex: 0,
      currentXCoordinate: 0,
      currentFlagPosition: 0,
      showFlag: false,
      showFlagContent: false,
      timeSeries: [],
      realPixelRatio: 1,
    };
  },
  computed: {
    outerViewBox() {
      return `0 0 ${this.baseGraphWidth} ${this.baseGraphHeight}`;
    },
    innerViewBox() {
      return `0 0 ${this.baseGraphWidth - 150} ${this.baseGraphHeight}`;
    },
    axisTransform() {
      return `translate(70, ${this.graphHeight - 100})`;
    },
    paddingBottomRootSvg() {
      return {
        paddingBottom: `${Math.ceil(this.baseGraphHeight * 100) / this.baseGraphWidth || 0}%`,
      };
    },
    deploymentFlagData() {
      return this.reducedDeploymentData.find(deployment => deployment.showDeploymentFlag);
    },
  },
  watch: {
    updateAspectRatio() {
      if (this.updateAspectRatio) {
        this.graphHeight = 450;
        this.graphWidth = 600;
        this.measurements = measurements.large;
        this.draw();
        eventHub.$emit('toggleAspectRatio');
      }
    },
    hoverData() {
      this.positionFlag();
    },
  },
  mounted() {
    this.draw();
  },
  methods: {
    draw() {
      const breakpointSize = bp.getBreakpointSize();
      const query = this.graphData.queries[0];
      this.margin = measurements.large.margin;
      if (this.smallGraph || breakpointSize === 'xs' || breakpointSize === 'sm') {
        this.graphHeight = 300;
        this.margin = measurements.small.margin;
        this.measurements = measurements.small;
      }
      this.unitOfDisplay = query.unit || '';
      this.yAxisLabel = this.graphData.y_label || 'Values';
      this.legendTitle = query.label || 'Average';
      this.graphWidth = this.$refs.baseSvg.clientWidth - this.margin.left - this.margin.right;
      this.graphHeight = this.graphHeight - this.margin.top - this.margin.bottom;
      this.baseGraphHeight = this.graphHeight - 50;
      this.baseGraphWidth = this.graphWidth;

      // pixel offsets inside the svg and outside are not 1:1
      this.realPixelRatio = this.$refs.baseSvg.clientWidth / this.baseGraphWidth;

      this.renderAxesPaths();
      this.formatDeployments();
    },
    handleMouseOverGraph(e) {
      let point = this.$refs.graphData.createSVGPoint();
      point.x = e.clientX;
      point.y = e.clientY;
      point = point.matrixTransform(this.$refs.graphData.getScreenCTM().inverse());
      point.x = point.x += 7;
      const firstTimeSeries = this.timeSeries[0];
      const timeValueOverlay = firstTimeSeries.timeSeriesScaleX.invert(point.x);
      const overlayIndex = bisectDate(firstTimeSeries.values, timeValueOverlay, 1);
      const d0 = firstTimeSeries.values[overlayIndex - 1];
      const d1 = firstTimeSeries.values[overlayIndex];
      if (d0 === undefined || d1 === undefined) return;
      const evalTime = timeValueOverlay - d0[0] > d1[0] - timeValueOverlay;
      const hoveredDataIndex = evalTime ? overlayIndex : overlayIndex - 1;
      const hoveredDate = firstTimeSeries.values[hoveredDataIndex].time;
      const currentDeployXPos = this.mouseOverDeployInfo(point.x);

      eventHub.$emit('hoverChanged', {
        hoveredDate,
        currentDeployXPos,
      });
    },
    renderAxesPaths() {
      this.timeSeries = createTimeSeries(
        this.graphData.queries,
        this.graphWidth,
        this.graphHeight,
        this.graphHeightOffset,
      );

      const axisXScale = d3.scaleTime()
        .range([0, this.graphWidth - 70]);
      const axisYScale = d3.scaleLinear()
        .range([this.graphHeight - this.graphHeightOffset, 0]);

      const allValues = this.timeSeries.reduce((all, { values }) => all.concat(values), []);
      axisXScale.domain(d3.extent(allValues, d => d.time));
      axisYScale.domain([0, d3.max(allValues.map(d => d.value))]);

      const xAxis = d3
        .axisBottom()
        .scale(axisXScale)
        .ticks(this.graphWidth / 120)
        .tickFormat(timeScaleFormat);

      const yAxis = d3
        .axisLeft()
        .scale(axisYScale)
        .ticks(measurements.yTicks);

      d3
        .select(this.$refs.baseSvg)
        .select('.x-axis')
        .call(xAxis);

      const width = this.graphWidth;
      d3
        .select(this.$refs.baseSvg)
        .select('.y-axis')
        .call(yAxis)
        .selectAll('.tick')
        .each(function createTickLines(d, i) {
          if (i > 0) {
            d3
              .select(this)
              .select('line')
              .attr('x2', width)
              .attr('class', 'axis-tick');
          } // Avoid adding the class to the first tick, to prevent coloring
        }); // This will select all of the ticks once they're rendered
    },
  },
};
</script>

<template>
  <div
    class="prometheus-graph"
    @mouseover="showFlagContent = true"
    @mouseleave="showFlagContent = false"
  >
    <h5 class="text-center graph-title">
      {{ graphData.title }}
    </h5>
    <div
      class="prometheus-svg-container"
      :style="paddingBottomRootSvg"
    >
      <svg
        :viewBox="outerViewBox"
        ref="baseSvg"
      >
        <g
          class="x-axis"
          :transform="axisTransform"
        />
        <g
          class="y-axis"
          transform="translate(70, 20)"
        />
        <graph-axis
          :graph-width="graphWidth"
          :graph-height="graphHeight"
          :margin="margin"
          :measurements="measurements"
          :y-axis-label="yAxisLabel"
        />
        <svg
          class="graph-data"
          :viewBox="innerViewBox"
          ref="graphData"
        >
          <graph-path
            v-for="(path, index) in timeSeries"
            :key="index"
            :generated-line-path="path.linePath"
            :generated-area-path="path.areaPath"
            :line-style="path.lineStyle"
            :line-color="path.lineColor"
            :area-color="path.areaColor"
          />
          <graph-deployment
            :deployment-data="reducedDeploymentData"
            :graph-height="graphHeight"
            :graph-height-offset="graphHeightOffset"
          />
          <rect
            class="prometheus-graph-overlay"
            :width="(graphWidth - 70)"
            :height="(graphHeight - 100)"
            transform="translate(-5, 20)"
            ref="graphOverlay"
            @mousemove="handleMouseOverGraph($event)"
          />
        </svg>
      </svg>
      <graph-flag
        :real-pixel-ratio="realPixelRatio"
        :current-x-coordinate="currentXCoordinate"
        :current-data="currentData"
        :graph-height="graphHeight"
        :graph-height-offset="graphHeightOffset"
        :show-flag-content="showFlagContent"
        :time-series="timeSeries"
        :unit-of-display="unitOfDisplay"
        :current-data-index="currentDataIndex"
        :legend-title="legendTitle"
        :deployment-flag-data="deploymentFlagData"
      />
    </div>
    <graph-legend
      v-if="showLegend"
      :legend-title="legendTitle"
      :time-series="timeSeries"
      :current-data-index="currentDataIndex"
      :unit-of-display="unitOfDisplay"
    />
  </div>
</template>

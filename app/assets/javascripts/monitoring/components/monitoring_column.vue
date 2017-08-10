<script>
  import d3 from 'd3';
  import monitoringLegends from './monitoring_legends.vue';
  import monitoringFlag from './monitoring_flag.vue';
  import monitoringDeployment from './monitoring_deployment.vue';
  import MonitoringMixin from '../mixins/monitoring_mixins';
  import eventHub from '../event_hub';
  import measurements from '../utils/measurements';
  import { formatRelevantDigits } from '../../lib/utils/number_utils';
  import bp from '../../breakpoints';

  const bisectDate = d3.bisector(d => d.time).left;

  export default {
    props: {
      columnData: {
        type: Object,
        required: true,
      },
      classType: {
        type: String,
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
    },

    mixins: [MonitoringMixin],

    data() {
      return {
        graphHeight: 450,
        graphWidth: 600,
        graphHeightOffset: 120,
        xScale: {},
        yScale: {},
        margin: {},
        data: [],
        unitOfDisplay: '',
        areaColorRgb: '#8fbce8',
        lineColorRgb: '#1f78d1',
        yAxisLabel: '',
        legendTitle: '',
        reducedDeploymentData: [],
        area: '',
        line: '',
        measurements: measurements.large,
        currentData: {
          time: new Date(),
          value: 0,
        },
        currentYCoordinate: 0,
        currentXCoordinate: 0,
        currentFlagPosition: 0,
        metricUsage: '',
        showFlag: false,
        showDeployInfo: true,
      };
    },

    components: {
      monitoringLegends,
      monitoringFlag,
      monitoringDeployment,
    },

    computed: {
      outterViewBox() {
        return `0 0 ${this.graphWidth} ${this.graphHeight}`;
      },

      innerViewBox() {
        if ((this.graphWidth - 150) > 0) {
          return `0 0 ${this.graphWidth - 150} ${this.graphHeight}`;
        }
        return '0 0 0 0';
      },

      axisTransform() {
        return `translate(70, ${this.graphHeight - 100})`;
      },

      paddingBottomRootSvg() {
        return {
          paddingBottom: `${(Math.ceil(this.graphHeight * 100) / this.graphWidth) || 0}%`,
        };
      },
    },

    methods: {
      draw() {
        const breakpointSize = bp.getBreakpointSize();
        const query = this.columnData.queries[0];
        this.margin = measurements.large.margin;
        if (breakpointSize === 'xs' || breakpointSize === 'sm') {
          this.graphHeight = 300;
          this.margin = measurements.small.margin;
          this.measurements = measurements.small;
        }
        this.data = query.result[0].values;
        this.unitOfDisplay = query.unit || '';
        this.yAxisLabel = this.columnData.y_label || 'Values';
        this.legendTitle = query.label || 'Average';
        this.graphWidth = this.$refs.baseSvg.clientWidth -
                     this.margin.left - this.margin.right;
        this.graphHeight = this.graphHeight - this.margin.top - this.margin.bottom;
        if (this.data !== undefined) {
          this.renderAxesPaths();
          this.formatDeployments();
        }
      },

      handleMouseOverGraph(e) {
        let point = this.$refs.graphData.createSVGPoint();
        point.x = e.clientX;
        point.y = e.clientY;
        point = point.matrixTransform(this.$refs.graphData.getScreenCTM().inverse());
        point.x = point.x += 7;
        const timeValueOverlay = this.xScale.invert(point.x);
        const overlayIndex = bisectDate(this.data, timeValueOverlay, 1);
        const d0 = this.data[overlayIndex - 1];
        const d1 = this.data[overlayIndex];
        if (d0 === undefined || d1 === undefined) return;
        const evalTime = timeValueOverlay - d0[0] > d1[0] - timeValueOverlay;
        this.currentData = evalTime ? d1 : d0;
        this.currentXCoordinate = Math.floor(this.xScale(this.currentData.time));
        const currentDeployXPos = this.mouseOverDeployInfo(point.x);
        this.currentYCoordinate = this.yScale(this.currentData.value);

        if (this.currentXCoordinate > (this.graphWidth - 200)) {
          this.currentFlagPosition = this.currentXCoordinate - 103;
        } else {
          this.currentFlagPosition = this.currentXCoordinate;
        }

        if (currentDeployXPos) {
          this.showFlag = false;
        } else {
          this.showFlag = true;
        }

        this.metricUsage = `${formatRelevantDigits(this.currentData.value)} ${this.unitOfDisplay}`;
      },

      renderAxesPaths() {
        const axisXScale = d3.time.scale()
          .range([0, this.graphWidth]);
        this.yScale = d3.scale.linear()
          .range([this.graphHeight - this.graphHeightOffset, 0]);
        axisXScale.domain(d3.extent(this.data, d => d.time));
        this.yScale.domain([0, d3.max(this.data.map(d => d.value))]);

        const xAxis = d3.svg.axis()
          .scale(axisXScale)
          .ticks(measurements.xTicks)
          .orient('bottom');

        const yAxis = d3.svg.axis()
          .scale(this.yScale)
          .ticks(measurements.yTicks)
          .orient('left');

        d3.select(this.$refs.baseSvg).select('.x-axis').call(xAxis);

        const width = this.graphWidth;
        d3.select(this.$refs.baseSvg).select('.y-axis').call(yAxis)
          .selectAll('.tick')
          .each(function createTickLines(d, i) {
            if (i > 0) {
              d3.select(this).select('line')
                .attr('x2', width)
                .attr('class', 'axis-tick');
            } // Avoid adding the class to the first tick, to prevent coloring
          }); // This will select all of the ticks once they're rendered

        this.xScale = d3.time.scale()
          .range([0, this.graphWidth - 70]);

        this.xScale.domain(d3.extent(this.data, d => d.time));

        const areaFunction = d3.svg.area()
          .x(d => this.xScale(d.time))
          .y0(this.graphHeight - this.graphHeightOffset)
          .y1(d => this.yScale(d.value))
          .interpolate('linear');

        const lineFunction = d3.svg.line()
          .x(d => this.xScale(d.time))
          .y(d => this.yScale(d.value));

        this.line = lineFunction(this.data);

        this.area = areaFunction(this.data);
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
    },

    mounted() {
      this.draw();
    },
  };
</script>
<template>
  <div
    :class="classType">
    <h5
      class="text-center graph-title">
        {{columnData.title}}
    </h5>
    <div
      class="prometheus-svg-container"
      :style="paddingBottomRootSvg">
      <svg
        :viewBox="outterViewBox"
        ref="baseSvg">
        <g
          class="x-axis"
          :transform="axisTransform">
        </g>
        <g
          class="y-axis"
          transform="translate(70, 20)">
        </g>
        <monitoring-legends
          :graph-width="graphWidth"
          :graph-height="graphHeight"
          :margin="margin"
          :measurements="measurements"
          :area-color-rgb="areaColorRgb"
          :legend-title="legendTitle"
          :y-axis-label="yAxisLabel"
          :metric-usage="metricUsage"
        />
        <svg
          class="graph-data"
          :viewBox="innerViewBox"
          ref="graphData">
            <path
              class="metric-area"
              :d="area"
              :fill="areaColorRgb"
              transform="translate(-5, 20)">
            </path>
            <path
              class="metric-line"
              :d="line"
              :stroke="lineColorRgb"
              fill="none"
              stroke-width="2"
              transform="translate(-5, 20)">
            </path>
            <rect
              class="prometheus-graph-overlay"
              :width="(graphWidth - 70)"
              :height="(graphHeight - 100)"
              transform="translate(-5, 20)"
              ref="graphOverlay"
              @mousemove="handleMouseOverGraph($event)">
            </rect>
            <monitoring-deployment
              :show-deploy-info="showDeployInfo"
              :deployment-data="reducedDeploymentData"
              :graph-height="graphHeight"
              :graph-height-offset="graphHeightOffset"
            />
            <monitoring-flag
              v-if="showFlag"
              :current-x-coordinate="currentXCoordinate"
              :current-y-coordinate="currentYCoordinate"
              :current-data="currentData"
              :current-flag-position="currentFlagPosition"
              :graph-height="graphHeight"
              :graph-height-offset="graphHeightOffset"
            />
        </svg>
      </svg>
    </div>
  </div>
</template>

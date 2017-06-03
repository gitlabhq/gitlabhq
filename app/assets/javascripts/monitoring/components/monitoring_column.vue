<script>
  /* eslint-disable no-param-reassign */
  /* global Breakpoints */
  import d3 from 'd3';
  import monitoringLegends from './monitoring_legends.vue';
  import monitoringFlag from './monitoring_flag.vue';
  import monitoringDeployment from './monitoring_deployment.vue';
  import eventHub from '../event_hub';
  import measurements from '../utils/measurements';
  import { formatRelevantDigits } from '../../lib/utils/number_utils';

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
    data() {
      return {
        height: 500,
        width: 600,
        xScale: {},
        yScale: {},
        margin: {},
        svgContainer: {},
        data: [],
        breakpointHandler: Breakpoints.get(),
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
      calculateViewBox() {
        return `0 0 ${this.width} ${this.height}`;
      },

      calculateInnerViewBox() {
        if ((this.width - 150) > 0) {
          return `0 0 ${this.width - 150} ${this.height}`;
        }
        return '0 0 0 0';
      },

      calculateAxisTransform() {
        return `translate(70, ${this.height - 100})`;
      },
    },

    methods: {
      draw() {
        const breakpointSize = this.breakpointHandler.getBreakpointSize();
        this.margin = measurements.large.margin;
        if (breakpointSize === 'xs' || breakpointSize === 'sm') {
          this.height = 300;
          this.margin = measurements.small.margin;
          this.measurements = measurements.small;
        }
        this.svgContainer = this.$el.querySelector('svg');
        this.data = ((this.columnData.queries[0]).result[0]).values;
        this.unitOfDisplay = (this.columnData.queries[0]).unit || 'N/A';
        this.yAxisLabel = this.columnData.y_axis || 'Values';
        this.legendTitle = (this.columnData.queries[0]).legend || 'Average';
        this.width = this.svgContainer.clientWidth -
                     this.margin.left - this.margin.right;
        this.height = this.height - this.margin.top - this.margin.bottom;
        if (this.data !== undefined) {
          this.renderAxisAndContainer();
        }
      },

      formatDeployments() {
        this.reducedDeploymentData = this.deploymentData.reduce((deploymentDataArray, deployment) => {
          const time = new Date(deployment.created_at);
          const xPos = Math.floor(this.xScale(time));

          time.setSeconds(this.data[0].time.getSeconds());

          if (xPos >= 0) {
            deploymentDataArray.push({
              id: deployment.id,
              time,
              sha: deployment.sha,
              tag: deployment.tag,
              ref: deployment.ref.name,
              xPos,
              showDeploymentFlag: false,
            });
          }

          return deploymentDataArray;
        }, []);
      },

      handleMouseOverGraph() {
        const rectOverlay = this.$el.querySelector('.prometheus-graph-overlay');
        const currentMouseXCoordinate = d3.mouse(rectOverlay)[0];
        const timeValueOverlay = this.xScale.invert(currentMouseXCoordinate);
        const overlayIndex = bisectDate(this.data, timeValueOverlay, 1);
        const d0 = this.data[overlayIndex - 1];
        const d1 = this.data[overlayIndex];
        if (d0 === undefined || d1 === undefined) return;
        const evalTime = timeValueOverlay - d0[0] > d1[0] - timeValueOverlay;
        this.currentData = evalTime ? d1 : d0;
        this.currentXCoordinate = Math.floor(this.xScale(this.currentData.time));
        const currentDeployXPos = this.mouseOverDeployInfo(currentMouseXCoordinate);
        this.currentYCoordinate = this.yScale(this.currentData.value);

        if (this.currentXCoordinate > (this.width - 200)) {
          this.currentFlagPosition = this.currentXCoordinate - 100;
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

      mouseOverDeployInfo(mouseXPos) {
        if (!this.reducedDeploymentData) return false;

        let dataFound = false;
        this.reducedDeploymentData.forEach((d) => {
          if (d.xPos >= mouseXPos - 10 && d.xPos <= mouseXPos + 10 && !dataFound) {
            dataFound = d.xPos + 1;

            d.showDeploymentFlag = true;
          } else {
            d.showDeploymentFlag = false;
          }
        });

        return dataFound;
      },

      renderAxisAndContainer() {
        d3.select(this.$el.querySelector('.prometheus-svg-container'))
        .attr({
          style: `padding-bottom: ${(Math.ceil(this.height * 100) / this.width)}%`, // Get the aspect ratio
        });

        const axisXScale = d3.time.scale()
          .range([0, this.width]);
        this.yScale = d3.scale.linear()
          .range([this.height - 120, 0]);
        axisXScale.domain(d3.extent(this.data, d => d.time));
        this.yScale.domain([0, d3.max(this.data.map(d => d.value))]);

        const xAxis = d3.svg.axis()
          .scale(axisXScale)
          .ticks(measurements.ticks)
          .orient('bottom');

        const yAxis = d3.svg.axis()
          .scale(this.yScale)
          .ticks(measurements.ticks)
          .orient('left');

        d3.select(this.svgContainer).select('.x-axis').call(xAxis);

        const width = this.width;
        d3.select(this.svgContainer).select('.y-axis').call(yAxis)
          .selectAll('.tick')
          .each(function createTickLines() {
            d3.select(this).select('line').attr('x2', width);
          }); // This will select all of the ticks once they're rendered

        this.xScale = d3.time.scale()
          .range([0, this.width - 70]);

        this.xScale.domain(d3.extent(this.data, d => d.time));

        const areaFunction = d3.svg.area()
          .x(d => this.xScale(d.time))
          .y0(this.height - 120)
          .y1(d => this.yScale(d.value))
          .interpolate('linear');

        const lineFunction = d3.svg.line()
          .x(d => this.xScale(d.time))
          .y(d => this.yScale(d.value));

        this.line = lineFunction(this.data);

        this.area = areaFunction(this.data);

        d3.select(this.svgContainer).select('.prometheus-graph-overlay')
        .on('mousemove', this.handleMouseOverGraph);
      },
    },

    watch: {
      updateAspectRatio() {
        if (this.updateAspectRatio) {
          this.height = 500;
          this.width = 600;
          this.measurements = measurements.large;
          this.draw();
          eventHub.$emit('toggleAspectRatio');
        }
      },
    },

    mounted() {
      this.draw();
      this.formatDeployments();
    },
  };
</script>
<template>
  <div 
    :class="classType">
    <h5 
      class="text-center">
        {{columnData.title}}
    </h5>
    <div 
      class="prometheus-svg-container">
      <svg :viewBox="calculateViewBox">
        <g
          class="x-axis"
          :transform="calculateAxisTransform">
        </g>
        <g
          class="y-axis"
          transform="translate(70, 20)">
        </g>
        <monitoring-legends 
          :width="width"
          :height="height"
          :margin="margin"
          :measurements="measurements"
          :area-color-rgb="areaColorRgb"
          :legend-title="legendTitle"
          :y-axis-label="yAxisLabel"
          :metric-usage="metricUsage"
        />
        <svg 
          class="graph-data"
          :viewBox="calculateInnerViewBox">
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
              :width="(width - 70)"
              :height="(height - 100)"
              transform="translate(-5, 20)">
            </rect>
            <monitoring-flag 
              v-show="showFlag"
              :current-x-coordinate="currentXCoordinate"
              :current-y-coordinate="currentYCoordinate"
              :current-data="currentData"
              :current-flag-position="currentFlagPosition"
              :height="height"
            />
            <monitoring-deployment
              :show-deploy-info="showDeployInfo"
              :deployment-data="reducedDeploymentData"
              :height="height"
            />
        </svg>
      </svg>
      <!--The gradient-->
      <svg
        class="hidden"
        height="0"
        width="0">
        <defs>
          <linearGradient
            id="shadow-gradient">
            <stop
              offset="0%"
              stop-color="#000"
              stop-opacity="0.4">
            </stop>
            <stop
              offset="100%"
              stop-color="#000"
              stop-opacity="0">
            </stop>
          </linearGradient>
        </defs>
      </svg>
    </div>
  </div>
</template>

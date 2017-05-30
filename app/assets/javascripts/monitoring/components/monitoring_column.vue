<script>
  /* global Breakpoints */
  import d3 from 'd3';
  import {
    dateFormat,
    timeFormat,
  } from '../constants';
  import eventHub from '../event_hub';
  import measurements from '../utils/measurements';
  import { formatRelevantDigits } from '../../lib/utils/number_utils';
  import { hsvToRgb } from '../../lib/utils/color_utils';

  const bisectDate = d3.bisector(d => d[0]).left;

  export default {
    props: {
      columnData: {
        type: Object,
        required: true,
        default: () => ({}),
      },
      classType: {
        type: String,
        required: true,
        default: 'col-md-6',
      },
      updateAspectRatio: {
        type: Boolean,
        required: true,
        default: false,
      },
    },
    data() {
      return {
        height: 0,
        width: 0,
        xScale: {},
        yScale: {},
        margin: {},
        svgContainer: {},
        data: [],
        axisLabelContainer: {},
        breakpointHandler: Breakpoints.get(),
        unitOfDisplay: '',
        areaColor: [],
        areaColorRgb: '',
        lineColor: [],
        lineColorRgb: '',
        circleColor: [],
        circleColorRgb: '',
        yAxisLabel: '',
        legendTitle: '',
      };
    },
    methods: {
      draw() {
        const breakpointSize = this.breakpointHandler.getBreakpointSize();
        let height = 500;
        this.margin = measurements.large.margin;
        this.measurements = measurements.large;
        if (breakpointSize === 'xs' || breakpointSize === 'sm') {
          height = 300;
          this.margin = measurements.small.margin;
          this.measurements = measurements.small;
        }
        this.svgContainer = this.$el.querySelector('svg');
        this.data = ((this.columnData.queries[0]).result[0]).values;
        this.unitOfDisplay = (this.columnData.queries[0]).unit || 'N/A';
        this.yAxisLabel = (this.columnData.queries[0]).y_axis || 'Values';
        this.legendTitle = (this.columnData.queries[0]).legend || 'Average';
        this.width = this.svgContainer.clientWidth -
                     this.margin.left - this.margin.right;
        this.height = height - this.margin.top - this.margin.bottom;
        if (this.data !== undefined) {
          this.renderAxisAndContainer();
          this.renderLabelAxisContainer();
        }
      },
      handleMouseOverGraph() {
        const rectOverlay = this.$el.querySelector('.prometheus-graph-overlay');
        const currentXCoordinate = d3.mouse(rectOverlay)[0];
        const timeValueOverlay = this.xScale2.invert(currentXCoordinate);
        const overlayIndex = bisectDate(this.data, timeValueOverlay, 1);
        const d0 = this.data[overlayIndex - 1];
        const d1 = this.data[overlayIndex];
        if (d0 === undefined || d1 === undefined) return;
        const evalTime = timeValueOverlay - d0[0] > d1[0] - timeValueOverlay;
        const currentData = evalTime ? d1 : d0;
        const currentDeployXPos = {};
        let currentTimeCoordinate = Math.floor(this.xScale2(currentData[0]));
        // const currentDeployXPos = this.deployments.mouseOverDeployInfo(currentXCoordinate, key);
        const maxValueFromData = d3.max(this.data.map(d => d[1]));
        const maxMetricValue = this.yScale(maxValueFromData);
        // Clear up all the pieces of the flag
        const graphContainer = d3.select(this.svgContainer);
        graphContainer.selectAll('.selected-metric-line').remove();
        graphContainer.selectAll('.circle-metric').remove();
        graphContainer.selectAll('.rect-text-metric:not(.deploy-info-rect)').remove();
        graphContainer.select('.mouse-over-flag').remove();

        // if (currentDeployXPos) return;

        const currentChart = graphContainer.select('.graph-data')
        .append('g').attr('class', 'mouse-over-flag');

        currentChart.append('line')
        .attr({
          class: 'selected-metric-line',
          x1: currentTimeCoordinate,
          y1: this.yScale(0),
          x2: currentTimeCoordinate,
          y2: maxMetricValue,
        })
        .attr('transform', 'translate(-5,20)');

        currentChart.append('circle')
          .attr('class', 'circle-metric')
          .attr('fill', this.circleColorRgb)
          .attr('stroke', '#000')
          .attr('cx', currentTimeCoordinate || currentDeployXPos)
          .attr('cy', this.yScale(currentData[1]))
          .attr('r', 5)
          .attr('transform', 'translate(-5,20)');

        // The little box with text
        if (currentTimeCoordinate >= this.width - 70 - 120) {
          currentTimeCoordinate = currentTimeCoordinate -= 100;
        }

        const rectTextMetric = currentChart.append('svg')
          .attr({
            class: 'rect-text-metric',
            x: currentTimeCoordinate,
            y: 0,
          });

        rectTextMetric.append('rect')
          .attr({
            class: 'rect-metric',
            x: 4,
            y: 1,
            rx: 2,
            width: 90,
            height: 40,
            transform: 'translate(-5,20)',
          });

        rectTextMetric.append('text')
          .attr({
            class: 'text-metric text-metric-bold',
            x: 8,
            y: 35,
            transform: 'translate(-5,20)',
          })
          .text(timeFormat(new Date(currentData[0] * 1000)));

        rectTextMetric.append('text')
          .attr({
            class: 'text-metric-date',
            x: 8,
            y: 15,
            transform: 'translate(-5,20)',
          })
          .text(dateFormat(new Date(currentData[0] * 1000)));

        d3.select(this.svgContainer).select('.text-metric-usage')
          .text(`${formatRelevantDigits(currentData[1])} ${this.unitOfDisplay}`);
      },
      renderAxisAndContainer() {
        d3.select(this.$el.querySelector('.prometheus-svg-container'))
        .attr({
          style: `padding-bottom: ${(Math.ceil(this.height * 100) / this.width)}%`, // Get the aspect ratio
        });

        const chart = d3.select(this.svgContainer)
          .attr('viewBox', `0 0 ${this.width} ${this.height}`);

        this.xScale = d3.time.scale()
          .range([0, this.width]);
        this.yScale = d3.scale.linear()
          .range([this.height - 120, 0]);
        this.xScale.domain(d3.extent(this.data, d => d[0]));
        this.yScale.domain([0, d3.max(this.data.map(d => d[1]))]);

        const xAxis = d3.svg.axis()
          .scale(this.xScale)
          .ticks(measurements.ticks)
          .orient('bottom');

        const yAxis = d3.svg.axis()
          .scale(this.yScale)
          .ticks(measurements.ticks)
          .orient('left');

        chart.append('g')
          .attr('class', 'x-axis')
          .attr('transform', `translate(70,${this.height - 100})`)
          .call(xAxis);

        const width = this.width;
        chart.append('g')
          .attr('class', 'y-axis')
          .attr('transform', 'translate(70,20)')
          .call(yAxis)
          .selectAll('.tick')
          .each(function createTickLines() {
            d3.select(this).select('line').attr('x2', width);
          }); // This will select all of the ticks once they're rendered

        const pathGroup = chart.append('svg')
          .attr('class', 'graph-data')
          .attr('viewBox', `0 0 ${this.width - 150} ${this.height}`);

        this.xScale2 = d3.time.scale()
          .range([0, this.width - 70]);

        this.xScale2.domain(d3.extent(this.data, d => d[0]));

        const area = d3.svg.area()
          .x(d => this.xScale2(d[0]))
          .y0(this.height - 120)
          .y1(d => this.yScale(d[1]))
          .interpolate('linear');

        const line = d3.svg.line()
          .x(d => this.xScale2(d[0]))
          .y(d => this.yScale(d[1]));

        pathGroup.append('path')
          .datum(this.data)
          .attr('d', area)
          .attr('class', 'metric-area')
          .attr('fill', this.areaColorRgb)
          .attr('transform', 'translate(-5,20)');

        pathGroup.append('path')
          .datum(this.data)
          .attr('class', 'metric-line')
          .attr('stroke', this.lineColorRgb)
          .attr('fill', 'none')
          .attr('stroke-width', 2)
          .attr('d', line)
          .attr('transform', 'translate(-5, 20)');

        // Overlay area for mouseover events
        pathGroup.append('rect')
          .attr('class', 'prometheus-graph-overlay')
          .attr('width', this.width - 70)
          .attr('height', this.height - 100)
          .attr('transform', 'translate(-5, 20)')
          .on('mousemove', this.handleMouseOverGraph);
      },
      renderLabelAxisContainer() {
        const axisLabelContainer = d3.select(this.svgContainer)
          .append('g')
            .attr('class', 'axis-label-container');

        axisLabelContainer.append('line')
          .attr('class', 'label-x-axis-line')
          .attr('stroke', '#000000')
          .attr('stroke-width', '1')
          .attr({
            x1: 10,
            y1: (this.height - this.margin.top) + this.measurements.axisLabelLineOffset,
            x2: this.width + 20,
            y2: (this.height - this.margin.top) + this.measurements.axisLabelLineOffset,
          });

        axisLabelContainer.append('line')
          .attr('class', 'label-y-axis-line')
          .attr('stroke', '#000000')
          .attr('stroke-width', '1')
          .attr({
            x1: 10,
            y1: 0,
            x2: 10,
            y2: (this.height - this.margin.top) + this.measurements.axisLabelLineOffset,
          });

        axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', -10)
          .attr('y', 50)
          .attr('width', this.measurements.backgroundLegend.width)
          .attr('height', this.measurements.backgroundLegend.height);

        axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('text-anchor', 'middle')
          .attr('transform', `translate(15, ${((this.height - this.margin.top) + this.measurements.axisLabelLineOffset) / 2}) rotate(-90)`)
          .text(this.yAxisLabel);

        axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', ((this.width + this.measurements.axisLabelLineOffset) / 2) - this.margin.right)
          .attr('y', this.height - 80)
          .attr('width', 30)
          .attr('height', 50);

        axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', ((this.width + this.measurements.axisLabelLineOffset) / 2) - this.margin.right)
          .attr('y', (this.height - this.margin.top) + this.measurements.axisLabelLineOffset)
          .attr('dy', '.35em')
          .text('Time');

        // The legends
        axisLabelContainer.append('rect')
          .attr('x', 20)
          .attr('y', this.height - this.measurements.legendOffset)
          .style('fill', this.areaColorRgb)
          .attr('width', this.measurements.legends.width)
          .attr('height', this.measurements.legends.height);

        axisLabelContainer.append('text')
          .attr('class', 'text-metric-title')
          .attr('x', 50)
          .attr('y', this.height - 40)
          .text(this.legendTitle);

        axisLabelContainer.append('text')
          .attr('class', 'text-metric-usage')
          .attr('x', 50)
          .attr('y', this.height - 25);
      },
      redraw() {
        // Remove event listeners and graphs, then redraw them
        d3.select(this.svgContainer).select('.prometheus-graph-overlay').on('mousemove', null);
        d3.select(this.svgContainer).remove();
        d3.select(this.$el).select('.prometheus-svg-container').append('svg');
        this.draw();
      },
    },

    watch: {
      updateAspectRatio: {
        handler() {
          if (this.updateAspectRatio) {
            this.redraw();
            eventHub.$emit('toggleAspectRatio');
          }
        },
      },
    },

    mounted() {
      const goldenRatioConjugate = 0.618033988749895;
      const hue = (Math.random() + goldenRatioConjugate) % 1;
      this.areaColor = hsvToRgb(hue, 0.4, 0.95);
      this.lineColor = hsvToRgb(hue, 0.7, 0.95);
      this.circleColor = hsvToRgb(hue, 0.9, 0.95);
      this.areaColorRgb = `rgb(${this.areaColor[0]}, ${this.areaColor[1]}, ${this.areaColor[2]})`;
      this.lineColorRgb = `rgb(${this.lineColor[0]}, ${this.lineColor[1]}, ${this.lineColor[2]})`;
      this.circleColorRgb = `rgb(${this.circleColor[0]}, ${this.circleColor[1]}, ${this.circleColor[2]})`;
      this.draw();
    },
  };
</script>
<template>
  <div :class="classType">
    <h5 class="text-center">{{columnData.title}}</h5>
    <div class="prometheus-svg-container">
      <svg>
      </svg>
    </div>
  </div>
</template>

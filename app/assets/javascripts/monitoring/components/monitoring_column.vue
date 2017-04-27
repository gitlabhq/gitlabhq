<script>
  import d3 from 'd3';
  import {
    dateFormat,
    timeFormat,
  } from '../constants';


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
    },
    data() {
      return {
        height: 0,
        width: 0,
        margin: {
          top: 80,
          right: 80,
          bottom: 100,
          left: 80,
        },
        marginLabelContainer: {
          top: 40,
          right: 10,
          bottom: 40,
          left: 10,
        },
        xScale: {},
        yScale: {},
        svgContainer: {},
        data: [],
        axisLabelContainer: {},
      };
    },
    methods: {
      handleMouseOverGraph() {
        const rectOverlay = this.$el.querySelector('.prometheus-graph-overlay');
        const currentXCoordinate = d3.mouse(rectOverlay)[0];
        const timeValueOverlay = this.xScale.invert(currentXCoordinate);
        const overlayIndex = bisectDate(this.data, timeValueOverlay, 1);
        const d0 = this.data[overlayIndex - 1];
        const d1 = this.data[overlayIndex];
        if(d0 === undefined || d1 === undefined) return;
        const evalTime = timeValueOverlay - d0[0] > d1[0] - timeValueOverlay;
        const currentData = evalTime ? d1 : d0;
        const currentDeployXPos = {};
        const currentTimeCoordinate = Math.floor(this.xScale(currentData[0]));
        // const currentDeployXPos = this.deployments.mouseOverDeployInfo(currentXCoordinate, key);
        const maxValueFromData = d3.max(this.data.map(d => d[1]));
        const maxMetricValue = this.yScale(maxValueFromData);
        // Clear up all the pieces of the flag
        const graphContainer = d3.select(this.svgContainer);
        graphContainer.selectAll('.selected-metric-line').remove();
        graphContainer.selectAll('.circle-metric').remove();
        graphContainer.selectAll('.rect-text-metric:not(.deploy-info-rect)').remove();

        // if (currentDeployXPos) return;

        const currentChart = graphContainer.select('g');

        currentChart.append('line')
        .attr({
          class: 'selected-metric-line',
          x1: currentTimeCoordinate,
          y1: this.yScale(0),
          x2: currentTimeCoordinate,
          y2: maxMetricValue,
        });

        currentChart.append('circle')
          .attr('class', 'circle-metric')
          .attr('fill', '#5b99f7')
          .attr('cx', currentTimeCoordinate || currentDeployXPos)
          .attr('cy', this.yScale(currentData[1]))
          .attr('r', 5);

        // The little box with text
        const rectTextMetric = graphContainer.select('g').append('svg')
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
          });

        rectTextMetric.append('text')
          .attr({
            class: 'text-metric text-metric-bold',
            x: 8,
            y: 35,
          })
          .text(timeFormat(new Date(currentData[0] * 1000)));

        rectTextMetric.append('text')
          .attr({
            class: 'text-metric-date',
            x: 8,
            y: 15,
          })
          .text(dateFormat(new Date(currentData[0] * 1000)));
      },
      renderAxisAndContainer() {
        const chart = d3.select(this.svgContainer)
          .attr("preserveAspectRatio", "xMinYMin meet")
          .attr("viewBox", this.viewBoxSize)
          .attr('class', 'svg-content')
            .append('g')
              .attr('transform', `translate(${this.margin.left},${this.margin.top})`);

        this.width = this.svgContainer.viewBox.baseVal.width - this.margin.left - this.margin.right;
        this.height = this.svgContainer.viewBox.baseVal.height - this.margin.top - this.margin.bottom;
        this.xScale = d3.time.scale()
          .range([0, this.width]);
        this.yScale = d3.scale.linear()
          .range([this.height, 0]);
        // this.xScale.domain(d3.extent(this.data, d => d[0]));
        this.xScale.domain(d3.extent(this.data, function(d) {
          if (d !== undefined) {
            return d[0];
          }
        }));
        this.yScale.domain([0, d3.max(this.data.map(d => d[1]))]);

        const xAxis = d3.svg.axis()
          .scale(this.xScale)
          .ticks(3)
          .orient('bottom');

        const yAxis = d3.svg.axis()
          .scale(this.yScale)
          .ticks(3) // TODO: Number of Ticks move it to a constant
          .orient('left');

        chart.append('g')
          .attr('class', 'x-axis')
          .attr('transform', `translate(0,${this.height})`)
          .call(xAxis);

        chart.append('g')
          .attr('class', 'y-axis')
          .call(yAxis);

        const area = d3.svg.area()
          .x(d => this.xScale(d[0]))
          .y0(this.height)
          .y1(d => this.yScale(d[1]))
          .interpolate('linear');

        const line = d3.svg.line()
          .x(d => this.xScale(d[0]))
          .y(d => this.yScale(d[1]));

        chart.append('path')
          .datum(this.data)
          .attr('d', area)
          .attr('class', 'metric-area')
          .attr('fill', '#edf3fc');

        chart.append('path')
          .datum(this.data)
          .attr('class', 'metric-line')
          .attr('stroke', '#5b99f7')
          .attr('fill', 'none')
          .attr('stroke-width', 2)
          .attr('d', line);

        //Overlay area for mouseover events
        chart.append('rect')
          .attr('class', 'prometheus-graph-overlay')
          .attr('width', this.width)
          .attr('height', this.height)
          .on('mousemove', this.handleMouseOverGraph);
      },
      renderLabelAxisContainer() {
        const axisLabelContainer = d3.select(this.svgContainer)
          .append('g')
            .attr('class', 'axis-label-container')
            .attr('transform', `translate(${this.marginLabelContainer.left},${this.marginLabelContainer.top})`);

        axisLabelContainer.append('line')
          .attr('class', 'label-x-axis-line')
          .attr('stroke', '#000000')
          .attr('stroke-width', '1')
          .attr({
            x1: 10,
            y1: this.svgContainer.viewBox.baseVal.height - this.margin.top,
            x2: (this.svgContainer.viewBox.baseVal.width - this.margin.right) + 10,
            y2: this.svgContainer.viewBox.baseVal.height - this.margin.top,
          });

        axisLabelContainer.append('line')
          .attr('class', 'label-y-axis-line')
          .attr('stroke', '#000000')
          .attr('stroke-width', '1')
          .attr({
            x1: 10,
            y1: 0,
            x2: 10,
            y2: this.svgContainer.viewBox.baseVal.height - this.margin.top,
          });

        axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', 0)
          .attr('y', 50)
          .attr('width', 30)
          .attr('height', 150);

        axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('text-anchor', 'middle')
          .attr('transform', `translate(15, ${(this.svgContainer.viewBox.baseVal.height - this.margin.top) / 2}) rotate(-90)`)
          .text('I.O.U Title'); // TODO: Put the appropiate title

        axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', (this.svgContainer.viewBox.baseVal.width / 2) - this.margin.right)
          .attr('y', this.svgContainer.viewBox.baseVal.height - 100)
          .attr('width', 30)
          .attr('height', 80);

        axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', (this.svgContainer.viewBox.baseVal.width / 2) - this.margin.right)
          .attr('y', this.svgContainer.viewBox.baseVal.height - this.margin.top)
          .attr('dy', '.35em')
          .text('Time');

        // TODO: Move this to the bottom of the graph, these are the legends
        axisLabelContainer.append('rect')
          .attr('x', this.svgContainer.viewBox.baseVal.width - 170)
          .attr('y', (this.svgContainer.viewBox.baseVal.height / 2) - 60)
          .style('fill', '#edf3fc')
          .attr('width', 20)
          .attr('height', 35);

        axisLabelContainer.append('text')
          .attr('class', 'text-metric-title')
          .attr('x', this.svgContainer.viewBox.baseVal.width - 140)
          .attr('y', (this.svgContainer.viewBox.baseVal.height / 2) - 50)
          .text('Average');

        axisLabelContainer.append('text')
          .attr('class', 'text-metric-usage')
          .attr('x', this.svgContainer.viewBox.baseVal.width - 140)
          .attr('y', (this.svgContainer.viewBox.baseVal.height / 2) - 25);
      }
    },
    mounted() {
      this.svgContainer = this.$el.querySelector('svg');
      this.data = (this.columnData.queries[0].result[0])[0].values || (this.columnData.queries[0].result[0])[0].value;
      if(this.classType === 'col-md-6') {
        this.viewBoxSize = '0 0 600 350';
      } else {
        this.viewBoxSize = '0 0 500 250';
      }
      if (this.data !== undefined) {
        this.renderAxisAndContainer();
        this.renderLabelAxisContainer();
      }
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

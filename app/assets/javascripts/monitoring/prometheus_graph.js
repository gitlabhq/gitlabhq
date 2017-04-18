/* eslint-disable no-new*/
/* global Flash */

import d3 from 'd3';
import statusCodes from '~/lib/utils/http_status';
import Deployments from './deployments';
import '../lib/utils/common_utils';
import '../flash';

const prometheusGraphsContainer = '.prometheus-graph';
const metricsEndpoint = 'metrics.json';
const timeFormat = d3.time.format('%H:%M%p');
const dayFormat = d3.time.format('%b %d, %Y');
const bisectDate = d3.bisector(d => d.time).left;
const extraAddedWidthParent = 100;

class PrometheusGraph {

  constructor() {
    this.margin = { top: 80, right: 180, bottom: 80, left: 100 };
    this.marginLabelContainer = { top: 40, right: 0, bottom: 40, left: 0 };
    const parentContainerWidth = $(prometheusGraphsContainer).parent().width() +
    extraAddedWidthParent;
    this.originalWidth = parentContainerWidth;
    this.originalHeight = 400;
    this.width = parentContainerWidth - this.margin.left - this.margin.right;
    this.height = 400 - this.margin.top - this.margin.bottom;
    this.backOffRequestCounter = 0;
    this.deployments = new Deployments(this.width, this.height);

    this.configureGraph();
    this.init();
  }

  createGraph() {
    Object.keys(this.data).forEach((key) => {
      const value = this.data[key];
      if (value.length > 0) {
        this.plotValues(value, key);
      }
    });
  }

  init() {
    this.getData().then((metricsResponse) => {
      if (Object.keys(metricsResponse).length === 0) {
        new Flash('Empty metrics', 'alert');
      } else {
        this.transformData(metricsResponse);
        this.createGraph();
        this.deployments.init(this.data[Object.keys(this.data)[0]]);
      }
    });
  }

  plotValues(valuesToPlot, key) {
    const x = d3.time.scale()
        .range([0, this.width]);

    const y = d3.scale.linear()
        .range([this.height, 0]);

    const prometheusGraphContainer = `${prometheusGraphsContainer}[graph-type=${key}]`;

    const graphSpecifics = this.graphSpecificProperties[key];

    const chart = d3.select(prometheusGraphContainer)
        .attr('width', this.width + this.margin.left + this.margin.right)
        .attr('height', this.height + this.margin.bottom + this.margin.top)
        .append('g')
          .attr('class', 'graph-container')
          .attr('transform', `translate(${this.margin.left},${this.margin.top})`);

    const axisLabelContainer = d3.select(prometheusGraphContainer)
      .attr('width', this.originalWidth + this.marginLabelContainer.left + this.marginLabelContainer.right)
      .attr('height', this.originalHeight + this.marginLabelContainer.bottom + this.marginLabelContainer.top)
      .append('g')
        .attr('transform', `translate(${this.marginLabelContainer.left},${this.marginLabelContainer.top})`);

    x.domain(d3.extent(valuesToPlot, d => d.time));
    y.domain([0, d3.max(valuesToPlot.map(metricValue => metricValue.value))]);

    const xAxis = d3.svg.axis()
        .scale(x)
        .ticks(this.commonGraphProperties.axis_no_ticks)
        .orient('bottom');

    const yAxis = d3.svg.axis()
        .scale(y)
        .ticks(this.commonGraphProperties.axis_no_ticks)
        .tickSize(-this.width)
        .outerTickSize(0)
        .orient('left');

    this.createAxisLabelContainers(axisLabelContainer, key);

    chart.append('g')
        .attr('class', 'x-axis')
        .attr('transform', `translate(0,${this.height})`)
        .call(xAxis);

    chart.append('g')
        .attr('class', 'y-axis')
        .call(yAxis);

    const area = d3.svg.area()
      .x(d => x(d.time))
      .y0(this.height)
      .y1(d => y(d.value))
      .interpolate('linear');

    const line = d3.svg.line()
    .x(d => x(d.time))
    .y(d => y(d.value));

    chart.append('path')
    .datum(valuesToPlot)
    .attr('d', area)
    .attr('class', 'metric-area')
    .attr('fill', graphSpecifics.area_fill_color);

    chart.append('path')
      .datum(valuesToPlot)
      .attr('class', 'metric-line')
      .attr('stroke', graphSpecifics.line_color)
      .attr('fill', 'none')
      .attr('stroke-width', this.commonGraphProperties.area_stroke_width)
      .attr('d', line);

    // Overlay area for the mouseover events
    chart.append('rect')
      .attr('class', 'prometheus-graph-overlay')
      .attr('width', this.width)
      .attr('height', this.height)
      .on('mousemove', this.handleMouseOverGraph.bind(this, x, y, valuesToPlot, chart, prometheusGraphContainer, key));
  }

  // The legends from the metric
  createAxisLabelContainers(axisLabelContainer, key) {
    const graphSpecifics = this.graphSpecificProperties[key];

    axisLabelContainer.append('line')
        .attr('class', 'label-x-axis-line')
        .attr('stroke', '#000000')
        .attr('stroke-width', '1')
        .attr({
          x1: 0,
          y1: this.originalHeight - this.marginLabelContainer.top,
          x2: this.originalWidth - this.margin.right,
          y2: this.originalHeight - this.marginLabelContainer.top,
        });

    axisLabelContainer.append('line')
          .attr('class', 'label-y-axis-line')
          .attr('stroke', '#000000')
          .attr('stroke-width', '1')
          .attr({
            x1: 0,
            y1: 0,
            x2: 0,
            y2: this.originalHeight - this.marginLabelContainer.top,
          });

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('text-anchor', 'middle')
          .attr('transform', `translate(15, ${(this.originalHeight - this.marginLabelContainer.top) / 2}) rotate(-90)`)
          .text(graphSpecifics.graph_legend_title);

    axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', (this.originalWidth / 2) - this.margin.right)
          .attr('y', this.originalHeight - this.marginLabelContainer.top - 20)
          .attr('width', 30)
          .attr('height', 80);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', (this.originalWidth / 2) - this.margin.right)
          .attr('y', this.originalHeight - this.marginLabelContainer.top)
          .attr('dy', '.35em')
          .text('Time');

    // Legends

    // Metric Usage
    axisLabelContainer.append('rect')
          .attr('x', this.originalWidth - 170)
          .attr('y', (this.originalHeight / 2) - 60)
          .style('fill', graphSpecifics.area_fill_color)
          .attr('width', 20)
          .attr('height', 35);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', this.originalWidth - 140)
          .attr('y', (this.originalHeight / 2) - 50)
          .text('Average');

    axisLabelContainer.append('text')
            .attr('class', 'text-metric-usage')
            .attr('x', this.originalWidth - 140)
            .attr('y', (this.originalHeight / 2) - 25);
  }

  handleMouseOverGraph(x, y, valuesToPlot, chart, prometheusGraphContainer, key) {
    const rectOverlay = document.querySelector(`${prometheusGraphContainer} .prometheus-graph-overlay`);
    const mouse = d3.mouse(rectOverlay)[0];
    const timeValueFromOverlay = x.invert(mouse);
    const timeValueIndex = bisectDate(valuesToPlot, timeValueFromOverlay, 1);
    const d0 = valuesToPlot[timeValueIndex - 1];
    const d1 = valuesToPlot[timeValueIndex];
    const currentData = timeValueFromOverlay - d0.time > d1.time - timeValueFromOverlay ? d1 : d0;
    const maxValueMetric = Math.floor(
      y(d3.max(valuesToPlot.map(metricValue => metricValue.value))),
    );
    const currentTimeCoordinate = Math.floor(x(currentData.time));
    const graphSpecifics = this.graphSpecificProperties[key];
    const shouldHideTextMetric = this.deployments.mouseOverDeployInfo(mouse);
    // Remove the current selectors
    d3.selectAll(`${prometheusGraphContainer} .selected-metric-line`).remove();
    d3.selectAll(`${prometheusGraphContainer} .circle-metric`).remove();
    d3.selectAll(`${prometheusGraphContainer} .rect-text-metric:not(.deploy-info-rect)`).remove();

    chart.append('line')
    .attr('class', 'selected-metric-line')
    .attr({
      x1: currentTimeCoordinate,
      y1: y(0),
      x2: currentTimeCoordinate,
      y2: maxValueMetric,
    });

    chart.append('circle')
    .attr('class', 'circle-metric')
    .attr('fill', graphSpecifics.line_color)
    .attr('cx', currentTimeCoordinate)
    .attr('cy', y(currentData.value))
    .attr('r', this.commonGraphProperties.circle_radius_metric);

    if (shouldHideTextMetric) return;

    // The little box with text
    const rectTextMetric = chart.append('svg')
    .attr('class', 'rect-text-metric')
    .attr('x', currentTimeCoordinate)
    .attr('y', 0);

    rectTextMetric.append('rect')
    .attr('class', 'rect-metric')
    .attr('x', 4)
    .attr('y', 1)
    .attr('rx', 2)
    .attr('width', this.commonGraphProperties.rect_text_width)
    .attr('height', this.commonGraphProperties.rect_text_height);

    rectTextMetric.append('text')
    .attr('x', 8)
    .attr('y', 35)
    .text(timeFormat(currentData.time));

    rectTextMetric.append('text')
    .attr('class', 'text-metric-date')
    .attr('x', 8)
    .attr('y', 15)
    .text(dayFormat(currentData.time));

    // Update the text
    d3.select(`${prometheusGraphContainer} .text-metric-usage`)
      .text(currentData.value.substring(0, 8));
  }

  configureGraph() {
    this.graphSpecificProperties = {
      cpu_values: {
        area_fill_color: '#edf3fc',
        line_color: '#5b99f7',
        graph_legend_title: 'CPU utilization (%)',
      },
      memory_values: {
        area_fill_color: '#fca326',
        line_color: '#fc6d26',
        graph_legend_title: 'Memory usage (MB)',
      },
    };

    this.commonGraphProperties = {
      area_stroke_width: 2,
      median_total_characters: 8,
      circle_radius_metric: 5,
      rect_text_width: 90,
      rect_text_height: 40,
      axis_no_ticks: 3,
    };
  }

  getData() {
    const maxNumberOfRequests = 3;
    return gl.utils.backOff((next, stop) => {
      $.ajax({
        url: metricsEndpoint,
        dataType: 'json',
      })
      .done((data, statusText, resp) => {
        if (resp.status === statusCodes.NO_CONTENT) {
          this.backOffRequestCounter = this.backOffRequestCounter += 1;
          if (this.backOffRequestCounter < maxNumberOfRequests) {
            next();
          } else {
            stop({
              status: resp.status,
              metrics: data,
            });
          }
        } else {
          stop({
            status: resp.status,
            metrics: data,
          });
        }
      }).fail(stop);
    })
    .then((resp) => {
      if (resp.status === statusCodes.NO_CONTENT) {
        return {};
      }
      return resp.metrics;
    })
    .catch(() => new Flash('An error occurred while fetching metrics.', 'alert'));
  }

  transformData(metricsResponse) {
    const metricTypes = {};
    Object.keys(metricsResponse.metrics).forEach((key) => {
      if (key === 'cpu_values' || key === 'memory_values') {
        const metricValues = (metricsResponse.metrics[key])[0];
        metricTypes[key] = metricValues.values.map(metric => ({
          time: new Date(metric[0] * 1000),
          value: metric[1],
        }));
      }
    });
    this.data = metricTypes;
  }
}

export default PrometheusGraph;

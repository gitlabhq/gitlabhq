/* eslint-disable no-new */
/* global Flash */

import d3 from 'd3';
import _ from 'underscore';
import statusCodes from '~/lib/utils/http_status';
import '~/lib/utils/common_utils';
import '~/flash';

const prometheusGraphsContainer = '.prometheus-graph';
const metricsEndpoint = 'metrics.json';
const timeFormat = d3.time.format('%H:%M');
const dayFormat = d3.time.format('%b %e, %a');
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
    this.configureGraph();
    this.init();
  }

  createGraph() {
    const self = this;
    _.each(this.data, (value, key) => {
      if (value.length > 0 && (key === 'cpu_values' || key === 'memory_values')) {
        self.plotValues(value, key);
      }
    });
  }

  init() {
    const self = this;
    this.getData().then((metricsResponse) => {
      if (metricsResponse === {}) {
        new Flash('Empty metrics', 'alert');
      } else {
        self.transformData(metricsResponse);
        self.createGraph();
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
          .attr('y', (this.originalHeight / 2) - 80)
          .style('fill', graphSpecifics.area_fill_color)
          .attr('width', 20)
          .attr('height', 35);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', this.originalWidth - 140)
          .attr('y', (this.originalHeight / 2) - 65)
          .text(graphSpecifics.graph_legend_title);

    axisLabelContainer.append('text')
            .attr('class', 'text-metric-usage')
            .attr('x', this.originalWidth - 140)
            .attr('y', (this.originalHeight / 2) - 50);
  }

  handleMouseOverGraph(x, y, valuesToPlot, chart, prometheusGraphContainer, key) {
    const rectOverlay = document.querySelector(`${prometheusGraphContainer} .prometheus-graph-overlay`);
    const timeValueFromOverlay = x.invert(d3.mouse(rectOverlay)[0]);
    const timeValueIndex = bisectDate(valuesToPlot, timeValueFromOverlay, 1);
    const d0 = valuesToPlot[timeValueIndex - 1];
    const d1 = valuesToPlot[timeValueIndex];
    const currentData = timeValueFromOverlay - d0.time > d1.time - timeValueFromOverlay ? d1 : d0;
    const maxValueMetric = y(d3.max(valuesToPlot.map(metricValue => metricValue.value)));
    const currentTimeCoordinate = x(currentData.time);
    const graphSpecifics = this.graphSpecificProperties[key];
    // Remove the current selectors
    d3.selectAll(`${prometheusGraphContainer} .selected-metric-line`).remove();
    d3.selectAll(`${prometheusGraphContainer} .circle-metric`).remove();
    d3.selectAll(`${prometheusGraphContainer} .rect-text-metric`).remove();
    d3.selectAll(`${prometheusGraphContainer} .text-metric`).remove();

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

    // The little box with text
    const rectTextMetric = chart.append('g')
    .attr('class', 'rect-text-metric')
    .attr('translate', `(${currentTimeCoordinate}, ${y(currentData.value)})`);

    rectTextMetric.append('rect')
    .attr('class', 'rect-metric')
    .attr('x', currentTimeCoordinate + 10)
    .attr('y', maxValueMetric)
    .attr('width', this.commonGraphProperties.rect_text_width)
    .attr('height', this.commonGraphProperties.rect_text_height);

    rectTextMetric.append('text')
    .attr('class', 'text-metric')
    .attr('x', currentTimeCoordinate + 35)
    .attr('y', maxValueMetric + 35)
    .text(timeFormat(currentData.time));

    rectTextMetric.append('text')
    .attr('class', 'text-metric-date')
    .attr('x', currentTimeCoordinate + 15)
    .attr('y', maxValueMetric + 15)
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
        graph_legend_title: 'CPU Usage (Cores)',
      },
      memory_values: {
        area_fill_color: '#fca326',
        line_color: '#fc6d26',
        graph_legend_title: 'Memory Usage (MB)',
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
    _.each(metricsResponse.metrics, (value, key) => {
      const metricValues = value[0].values;
      metricTypes[key] = _.map(metricValues, metric => ({
        time: new Date(metric[0] * 1000),
        value: metric[1],
      }));
    });
    this.data = metricTypes;
  }
}

export default PrometheusGraph;

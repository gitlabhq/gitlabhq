/* global d3 */
const prometheusGraphContainer = '.prometheus-graph';

window.d3 = require('d3');
window._ = require('underscore');

const metricsEndpoint = 'metrics.json';
const timeFormat = d3.time.format('%H:%M');
const dayFormat = d3.time.format('%b %e, %a');

class PrometheusGraph {

  constructor() {
    this.margin = { top: 80, right: 0, bottom: 80, left: 100 };
    this.marginLabelContainer = { top: 40, right: 0, bottom: 40, left: 0 };
    const parentContainerWidth = $(prometheusGraphContainer).parent().width();
    this.bisectDate = d3.bisector(d => d.time).left;
    this.width = parentContainerWidth - this.margin.left - this.margin.right;
    this.height = 400 - this.margin.top - this.margin.bottom;
    this.originalWidth = parentContainerWidth;
    this.originalHeight = 400;

    const self = this;
    this.getData().then((metricsResponse) => {
      self.data = self.transformData(metricsResponse);
      self.createGraph();
    });
  }

  createGraph() {
    const self = this;
    _.each(self.data, (value, key) => {
      // Don't create a graph if there's no data
      if (value.length > 0 && (key === 'cpu_values')) {
        self.plotValues(value);
      }
    });
  }

  plotValues(valuesToPlot) {
    const self = this;
    
    // Mean value of the current graph
    const median = d3.mean(valuesToPlot, data => data.value);

    const x = d3.time.scale()
        .range([0, this.width]);

    const y = d3.scale.linear()
        .range([this.height, 0]);

    const chart = d3.select(prometheusGraphContainer)
        .attr('width', this.width + this.margin.left + this.margin.right)
        .attr('height', this.height + this.margin.bottom + this.margin.top)
        .append('g')
          .attr('transform', `translate(${this.margin.left},${this.margin.top})`);

   // Chart container for the axis labels
   const axisLabelContainer = d3.select(prometheusGraphContainer)
        .attr('width', this.originalWidth + this.marginLabelContainer.left + this.marginLabelContainer.right)
        .attr('height', this.originalHeight + this.marginLabelContainer.bottom + this.marginLabelContainer.top)
        .append('g')
          .attr('transform', `translate(${this.marginLabelContainer.left},${this.marginLabelContainer.top})`);

    x.domain(d3.extent(valuesToPlot, d => d.time));
    y.domain([0, d3.max(valuesToPlot.map(metricValue => metricValue.value))]);

    const xAxis = d3.svg.axis()
        .scale(x)
        .orient('bottom');

    const yAxis = d3.svg.axis()
        .scale(y)
        .orient('left');

    // Axis label container
    axisLabelContainer.append('line')
        .attr('class', 'label-x-axis-line')
        .attr('stroke', '#000000')
        .attr('stroke-width', '1')
        .attr({
          x1: 0,
          y1: this.originalHeight - this.marginLabelContainer.top,
          x2: this.originalWidth,
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
          .text('CPU Usage');

    axisLabelContainer.append('rect')
          .attr('class', 'rect-axis-text')
          .attr('x', this.originalWidth / 2)
          .attr('y', this.originalHeight - this.marginLabelContainer.top - 20)
          .attr('width', 30)
          .attr('height', 80);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', this.originalWidth / 2)
          .attr('y', this.originalHeight - this.marginLabelContainer.top)
          .attr('dy', '.35em')
          .text('Time');

    // Legends

    // Metric Usage
    axisLabelContainer.append('rect')
          .attr('x', this.originalWidth - 120)
          .attr('y', 0)
          .style('fill', '#EDF3FC')
          .attr('width', 20)
          .attr('height', 35);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', this.originalWidth - 80)
          .attr('y', 10)
          .text('CPU Usage');

    axisLabelContainer.append('text')
            .attr('class', 'text-metric-usage')
            .attr('x', this.originalWidth - 80)
            .attr('y', 30);

    // Mean value of the usage

    axisLabelContainer.append('rect')
          .attr('x', this.originalWidth - 240)
          .attr('y', 0)
          .style('fill', '#5b99f7')
          .attr('width', 20)
          .attr('height', 35);

    axisLabelContainer.append('text')
          .attr('class', 'label-axis-text')
          .attr('x', this.originalWidth - 200)
          .attr('y', 10)
          .text('Median');

    axisLabelContainer.append('text')
            .attr('class', 'text-median-metric')
            .attr('x', this.originalWidth - 200)
            .attr('y', 30)
            .text(median.toString().substring(0, 8));


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

    chart.append('path')
    .datum(valuesToPlot)
    .attr('d', area)
    .attr('class', 'cpu-values')
    .style('fill', '#EDF3FC');

    chart.append('line')
        .attr('class', 'median-cpu-line')
        .attr('stroke', '#5b99f7')
        .attr('stroke-width', '2')
        .attr({
          x1: x(d3.extent(valuesToPlot, d => d.time)[0]),
          y1: y(median),
          x2: x(d3.extent(valuesToPlot, d => d.time)[1]),
          y2: y(median),
        });
    // Overlay area for the mouseover events
    chart.append('rect')
      .attr('class', 'prometheus-graph-overlay')
      .attr('width', this.width)
      .attr('height', this.height)
      .on('mousemove', function handleMouseOver() {
        const x0 = x.invert(d3.mouse(this)[0]);
        const i = self.bisectDate(valuesToPlot, x0, 1);
        const d0 = valuesToPlot[i - 1];
        const d1 = valuesToPlot[i];
        const d = x0 - d0.time > d1.time - x0 ? d1 : d0;
        // Remove the current selectors
        d3.selectAll('.selected-metric-line').remove();
        d3.selectAll('.upper-circle-metric').remove();
        d3.selectAll('.lower-circle-metric').remove();
        d3.selectAll('.rect-text-metric').remove();
        d3.selectAll('.text-metric').remove();

        chart.append('line')
        .attr('class', 'selected-metric-line')
        .attr('stroke', '#000000')
        .attr('stroke-width', '1')
        .attr({
          x1: x(d.time),
          y1: y(0),
          x2: x(d.time),
          y2: y(d3.max(valuesToPlot.map(metricValue => metricValue.value))),
        });

        chart.append('circle')
        .attr('class', 'upper-circle-metric')
        .attr('cx', x(d.time))
        .attr('cy', y(d.value))
        .attr('r', 3);

        chart.append('circle')
        .attr('class', 'lower-circle-metric')
        .attr('cx', x(d.time))
        .attr('cy', y(0))
        .attr('r', 3);

        // The little box with text
        const rectTextMetric = chart.append('g')
        .attr('class', 'rect-text-metric')
        .attr('translate', `(${x(d.time)}, ${y(d.value)})`);

        rectTextMetric.append('rect')
        .attr('class', 'rect-metric')
        .attr('x', x(d.time) + 10)
        .attr('y', y(d3.max(valuesToPlot.map(metricValue => metricValue.value))))
        .attr('width', 90)
        .attr('height', 40);

        rectTextMetric.append('text')
        .attr('class', 'text-metric')
        .attr('x', x(d.time) + 35)
        .attr('y', y(d3.max(valuesToPlot.map(metricValue => metricValue.value))) + 35)
        .text(timeFormat(d.time));

        rectTextMetric.append('text')
        .attr('class', 'text-metric-date')
        .attr('x', x(d.time) + 15)
        .attr('y', y(d3.max(valuesToPlot.map(metricValue => metricValue.value))) + 15)
        .text(dayFormat(d.time));

        // Update the text
        d3.select('.text-metric-usage')
          .text(d.value.substring(0, 8));
      });
  }

  getData() {
    return $.ajax({
      url: metricsEndpoint,
      dataType: 'json',
    }).done(metricsResponse => metricsResponse);
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
    return metricTypes;
  }
}

module.exports = PrometheusGraph;

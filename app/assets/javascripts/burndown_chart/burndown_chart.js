import { select, mouse } from 'd3-selection';
import { bisector, max } from 'd3-array';
import { timeFormat } from 'd3-time-format';
import { scaleTime, scaleLinear } from 'd3-scale';
import { axisBottom, axisLeft } from 'd3-axis';
import { line } from 'd3-shape';
import { transition } from 'd3-transition';
import { easeLinear } from 'd3-ease';

const d3 = {
  select,
  mouse,
  bisector,
  max,
  timeFormat,
  scaleTime,
  scaleLinear,
  axisBottom,
  axisLeft,
  line,
  transition,
  easeLinear };
const margin = { top: 5, right: 65, bottom: 30, left: 50 };
// const parseDate = d3.timeFormat('%Y-%m-%d');
const bisectDate = d3.bisector(d => d.date).left;
const tooltipPadding = { x: 8, y: 3 };
const tooltipDistance = 15;

export default class BurndownChart {
  constructor({ container, startDate, dueDate }) {
    this.canvas = d3.select(container).append('svg')
      .attr('height', '100%')
      .attr('width', '100%');

    // create svg nodes
    this.chartGroup = this.canvas.append('g').attr('class', 'chart');
    this.xAxisGroup = this.chartGroup.append('g').attr('class', 'x axis');
    this.yAxisGroup = this.chartGroup.append('g').attr('class', 'y axis');
    this.idealLinePath = this.chartGroup.append('path').attr('class', 'ideal line');
    this.actualLinePath = this.chartGroup.append('path').attr('class', 'actual line');

    this.xAxisGroup.append('line').attr('class', 'domain-line');

    // create y-axis label
    this.label = 'Remaining';
    const yAxisLabel = this.yAxisGroup.append('g').attr('class', 'axis-label');
    this.yAxisLabelText = yAxisLabel.append('text').text(this.label);
    this.yAxisLabelBBox = this.yAxisLabelText.node().getBBox();
    this.yAxisLabelLineA = yAxisLabel.append('line');
    this.yAxisLabelLineB = yAxisLabel.append('line');

    // create chart legend
    this.chartLegendGroup = this.chartGroup.append('g').attr('class', 'legend');
    this.chartLegendGroup.append('rect');

    this.chartLegendIdealKey = this.chartLegendGroup.append('g');
    this.chartLegendIdealKey.append('line').attr('class', 'ideal line');
    this.chartLegendIdealKey.append('text').text('Guideline');
    this.chartLegendIdealKeyBBox = this.chartLegendIdealKey.select('text').node().getBBox();

    this.chartLegendActualKey = this.chartLegendGroup.append('g');
    this.chartLegendActualKey.append('line').attr('class', 'actual line');
    this.chartLegendActualKey.append('text').text('Progress');
    this.chartLegendActualKeyBBox = this.chartLegendActualKey.select('text').node().getBBox();

    // create tooltips
    this.chartFocus = this.chartGroup.append('g').attr('class', 'focus').style('display', 'none');
    this.chartFocus.append('circle').attr('r', 4);
    this.tooltipGroup = this.chartFocus.append('g').attr('class', 'chart-tooltip');
    this.tooltipGroup.append('rect').attr('rx', 3).attr('ry', 3);
    this.tooltipGroup.append('text');

    this.chartOverlay = this.chartGroup.append('rect').attr('class', 'overlay')
      .on('mouseover', () => this.chartFocus.style('display', null))
      .on('mouseout', () => this.chartFocus.style('display', 'none'))
      .on('mousemove', () => this.handleMousemove());

    // parse start and due dates
    this.startDate = new Date(startDate);
    this.dueDate = new Date(dueDate);

    // get width and height
    const dimensions = this.canvas.node().getBoundingClientRect();
    this.width = dimensions.width;
    this.height = dimensions.height;
    this.chartWidth = this.width - (margin.left + margin.right);
    this.chartHeight = this.height - (margin.top + margin.bottom);

    // set default scale domains
    this.xMax = this.dueDate;
    this.yMax = 1;

    // create scales
    this.xScale = d3.scaleTime()
      .range([0, this.chartWidth])
      .domain([this.startDate, this.xMax]);

    this.yScale = d3.scaleLinear()
      .range([this.chartHeight, 0])
      .domain([0, this.yMax]);

    // create axes
    this.xAxis = d3.axisBottom()
      .scale(this.xScale)
      .tickFormat(d3.timeFormat('%b %-d'))
      .tickPadding(6)
      .tickSize(4, 0);

    this.yAxis = d3.axisLeft()
      .scale(this.yScale)
      .tickPadding(6)
      .tickSize(4, 0);

    // create lines
    this.line = d3.line()
      .x(d => this.xScale(new Date(d.date)))
      .y(d => this.yScale(d.value));

    // render the chart
    this.scheduleRender();
  }

  // set data and force re-render
  setData(data, { label = 'Remaining', animate } = {}) {
    this.data = data.map(datum => ({
      date: new Date(datum[0]),
      value: parseInt(datum[1], 10),
    })).sort((a, b) => (a.date - b.date));

    // adjust axis domain to correspond with data
    this.xMax = Math.max(d3.max(this.data, d => d.date) || 0, this.dueDate);
    this.yMax = d3.max(this.data, d => d.value) || 1;

    this.xScale.domain([this.startDate, this.xMax]);
    this.yScale.domain([0, this.yMax]);

    // calculate the bounding box for the axis label if updated
    // (this must be done here to prevent layout thrashing)
    if (this.label !== label) {
      this.label = label;
      this.yAxisLabelBBox = this.yAxisLabelText.text(label).node().getBBox();
    }

    // set ideal line data
    if (this.data.length > 1) {
      const idealStart = this.data[0] || { date: this.startDate, value: 0 };
      const idealEnd = { date: this.dueDate, value: 0 };
      this.idealData = [idealStart, idealEnd];
    }

    this.scheduleLineAnimation = !!animate;
    this.scheduleRender();
  }

  handleMousemove() {
    if (!this.data) return;

    const mouseOffsetX = d3.mouse(this.chartOverlay.node())[0];
    const dateOffset = this.xScale.invert(mouseOffsetX);
    const i = bisectDate(this.data, dateOffset, 1);
    const d0 = this.data[i - 1];
    const d1 = this.data[i];
    if (d1 == null || dateOffset - d0.date < d1.date - dateOffset) {
      this.renderTooltip(d0);
    } else {
      this.renderTooltip(d1);
    }
  }

  // reset width and height to match the svg element, then re-render if necessary
  handleResize() {
    const dimensions = this.canvas.node().getBoundingClientRect();
    if (this.width !== dimensions.width || this.height !== dimensions.height) {
      this.width = dimensions.width;
      this.height = dimensions.height;

      // adjust axis range to correspond with chart size
      this.chartWidth = this.width - (margin.left + margin.right);
      this.chartHeight = this.height - (margin.top + margin.bottom);

      this.xScale.range([0, this.chartWidth]);
      this.yScale.range([this.chartHeight, 0]);

      this.scheduleRender();
    }
  }

  scheduleRender() {
    if (this.queuedRender == null) {
      this.queuedRender = requestAnimationFrame(() => this.render());
    }
  }

  render() {
    this.queuedRender = null;
    this.renderedTooltipPoint = null; // force tooltip re-render

    this.xAxis.ticks(Math.floor(this.chartWidth / 120));
    this.yAxis.ticks(Math.min(Math.floor(this.chartHeight / 60), this.yMax));

    this.chartGroup.attr('transform', `translate(${margin.left}, ${margin.top})`);
    this.xAxisGroup.attr('transform', `translate(0, ${this.chartHeight})`);

    this.xAxisGroup.call(this.xAxis);
    this.yAxisGroup.call(this.yAxis);

    // replace x-axis line with one which continues into the right margin
    this.xAxisGroup.select('.domain').remove();
    this.xAxisGroup.select('.domain-line').attr('x1', 0).attr('x2', this.chartWidth + margin.right);

    // update y-axis label
    const axisLabelOffset = (this.yAxisLabelBBox.height / 2) - margin.left;
    const axisLabelPadding = (this.chartHeight - this.yAxisLabelBBox.width - 10) / 2;

    this.yAxisLabelText
      .attr('y', 0 - margin.left)
      .attr('x', 0 - (this.chartHeight / 2))
      .attr('dy', '1em')
      .style('text-anchor', 'middle')
      .attr('transform', 'rotate(-90)');
    this.yAxisLabelLineA
      .attr('x1', axisLabelOffset)
      .attr('x2', axisLabelOffset)
      .attr('y1', 0)
      .attr('y2', axisLabelPadding);
    this.yAxisLabelLineB
      .attr('x1', axisLabelOffset)
      .attr('x2', axisLabelOffset)
      .attr('y1', this.chartHeight - axisLabelPadding)
      .attr('y2', this.chartHeight);

    // update legend
    const legendPadding = 10;
    const legendSpacing = 5;

    const idealBBox = this.chartLegendIdealKeyBBox;
    const actualBBox = this.chartLegendActualKeyBBox;
    const keyWidth = Math.ceil(Math.max(idealBBox.width, actualBBox.width));
    const keyHeight = Math.ceil(Math.max(idealBBox.height, actualBBox.height));

    const idealKeyOffset = legendPadding;
    const actualKeyOffset = legendPadding + keyHeight + legendSpacing;
    const legendWidth = (legendPadding * 2) + 24 + keyWidth;
    const legendHeight = (legendPadding * 2) + (keyHeight * 2) + legendSpacing;
    const legendOffset = (this.chartWidth + margin.right) - legendWidth - 1;

    this.chartLegendGroup.select('rect')
      .attr('width', legendWidth)
      .attr('height', legendHeight);

    this.chartLegendGroup.selectAll('text')
      .attr('x', 24)
      .attr('dy', '1em');
    this.chartLegendGroup.selectAll('line')
      .attr('y1', keyHeight / 2)
      .attr('y2', keyHeight / 2)
      .attr('x1', 0)
      .attr('x2', 18);

    this.chartLegendGroup.attr('transform', `translate(${legendOffset}, 0)`);
    this.chartLegendIdealKey.attr('transform', `translate(${legendPadding}, ${idealKeyOffset})`);
    this.chartLegendActualKey.attr('transform', `translate(${legendPadding}, ${actualKeyOffset})`);

    // update overlay
    this.chartOverlay
      .attr('fill', 'none')
      .attr('pointer-events', 'all')
      .attr('width', this.chartWidth)
      .attr('height', this.chartHeight);

    // render lines if data available
    if (this.data != null && this.data.length > 1) {
      this.actualLinePath.datum(this.data).attr('d', this.line);
      this.idealLinePath.datum(this.idealData).attr('d', this.line);

      if (this.scheduleLineAnimation === true) {
        this.scheduleLineAnimation = false;

        // hide tooltips until animation is finished
        this.chartFocus.attr('opacity', 0);

        this.constructor.animateLinePath(this.actualLinePath, 800, () => {
          this.chartFocus.attr('opacity', null);
        });
      }
    }
  }

  renderTooltip(datum) {
    if (this.renderedTooltipPoint === datum) return;
    this.renderedTooltipPoint = datum;

    // generate tooltip content
    const format = d3.timeFormat('%b %-d, %Y');
    const tooltip = `${datum.value} ${this.label} / ${format(datum.date)}`;

    // move the tooltip point of origin to the point on the graph
    const x = this.xScale(datum.date);
    const y = this.yScale(datum.value);

    const textSize = this.tooltipGroup.select('text').text(tooltip).node().getBBox();
    const width = textSize.width + (tooltipPadding.x * 2);
    const height = textSize.height + (tooltipPadding.y * 2);

    // calculate bounraries
    const xMin = 0 - x - margin.left;
    const yMin = 0 - y - margin.top;
    const xMax = (this.chartWidth + margin.right) - x - width;
    const yMax = (this.chartHeight + margin.bottom) - y - height;

    // try to fit tooltip above point
    let xOffset = 0 - Math.floor(width / 2);
    let yOffset = 0 - tooltipDistance - height;

    if (yOffset <= yMin) {
      // else try to fit tooltip to the right
      xOffset = tooltipDistance;
      yOffset = 0 - Math.floor(height / 2);

      if (xOffset >= xMax) {
        // else place tooltip on the left
        xOffset = 0 - tooltipDistance - width;
      }
    }

    // ensure coordinates keep the entire tooltip in-bounds
    xOffset = Math.max(xMin, Math.min(xMax, xOffset));
    yOffset = Math.max(yMin, Math.min(yMax, yOffset));

    // move everything into place
    this.chartFocus.attr('transform', `translate(${x}, ${y})`);
    this.tooltipGroup.attr('transform', `translate(${xOffset}, ${yOffset})`);

    this.tooltipGroup.select('text')
      .attr('dy', '1em')
      .attr('x', tooltipPadding.x)
      .attr('y', tooltipPadding.y);

    this.tooltipGroup.select('rect')
      .attr('width', width)
      .attr('height', height);
  }

  animateResize(seconds = 5) {
    this.ticksLeft = this.ticksLeft || 0;
    if (this.ticksLeft <= 0) {
      const interval = setInterval(() => {
        this.ticksLeft -= 1;
        if (this.ticksLeft <= 0) {
          clearInterval(interval);
        }
        this.handleResize();
      }, 20);
    }
    this.ticksLeft = seconds * 50;
  }

  static animateLinePath(path, duration = 1000, cb) {
    const lineLength = path.node().getTotalLength();
    const linearTransition = d3.transition().duration(duration).ease(d3.easeLinear);
    path
      .attr('stroke-dasharray', `${lineLength} ${lineLength}`)
      .attr('stroke-dashoffset', lineLength)
      .transition(linearTransition)
        .attr('stroke-dashoffset', 0)
        .on('end', () => {
          path.attr('stroke-dasharray', null);
          if (cb) cb();
        });
  }
}

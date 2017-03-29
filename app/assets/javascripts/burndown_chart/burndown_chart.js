import d3 from 'd3';

const margin = { top: 5, right: 65, bottom: 30, left: 50 };
const parseDate = d3.time.format('%Y-%m-%d').parse;

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

    // parse start and due dates
    this.startDate = parseDate(startDate);
    this.dueDate = parseDate(dueDate);

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
    this.xScale = d3.time.scale()
      .range([0, this.chartWidth])
      .domain([this.startDate, this.xMax]);

    this.yScale = d3.scale.linear()
      .range([this.chartHeight, 0])
      .domain([0, this.yMax]);

    // create axes
    this.xAxis = d3.svg.axis()
      .scale(this.xScale)
      .orient('bottom')
      .tickFormat(d3.time.format('%b %-d'))
      .tickPadding(6)
      .tickSize(4, 0);

    this.yAxis = d3.svg.axis()
      .scale(this.yScale)
      .orient('left')
      .tickPadding(6)
      .tickSize(4, 0);

    // create lines
    this.line = d3.svg.line()
      .x(d => this.xScale(d.date))
      .y(d => this.yScale(d.value));

    // render the chart
    this.queueRender();
  }

  // set data and force re-render
  setData(data) {
    this.data = data.map(datum => ({
      date: parseDate(datum[0]),
      value: parseInt(datum[1], 10),
    })).sort((a, b) => (a.date - b.date));

    // adjust axis domain to correspond with data
    this.xMax = Math.max(d3.max(this.data, d => d.date) || 0, this.dueDate);
    this.yMax = d3.max(this.data, d => d.value) || 1;

    this.xScale.domain([this.startDate, this.xMax]);
    this.yScale.domain([0, this.yMax]);

    // set our ideal line data
    if (this.data.length > 1) {
      const idealStart = this.data[0] || { date: this.startDate, value: 0 };
      const idealEnd = { date: this.xMax, value: 0 };
      this.idealData = [idealStart, idealEnd];
    }

    this.queueRender();
  }

  // reset width and height to match the svg element, then re-render if necessary
  resize() {
    const dimensions = this.canvas.node().getBoundingClientRect();
    if (this.width !== dimensions.width || this.height !== dimensions.height) {
      this.width = dimensions.width;
      this.height = dimensions.height;

      // adjust axis range to correspond with chart size
      this.chartWidth = this.width - (margin.left + margin.right);
      this.chartHeight = this.height - (margin.top + margin.bottom);

      this.xScale.range([0, this.chartWidth]);
      this.yScale.range([this.chartHeight, 0]);

      this.queueRender();
    }
  }

  render() {
    this.queuedRender = null;

    this.xAxis.ticks(Math.floor(this.chartWidth / 120));
    this.yAxis.ticks(Math.min(Math.floor(this.chartHeight / 60), this.yMax));

    this.chartGroup.attr('transform', `translate(${margin.left}, ${margin.top})`);
    this.xAxisGroup.attr('transform', `translate(0, ${this.chartHeight})`);

    this.xAxisGroup.call(this.xAxis);
    this.yAxisGroup.call(this.yAxis);

    // replace x-axis line with one which continues into the right margin
    this.xAxisGroup.select('.domain').remove();
    this.xAxisGroup.select('.domain-line').attr('x1', 0).attr('x2', this.chartWidth + margin.right);

    if (this.data != null && this.data.length > 1) {
      this.actualLinePath.datum(this.data).attr('d', this.line);
      this.idealLinePath.datum(this.idealData).attr('d', this.line);
    }
  }

  queueRender() {
    this.queuedRender = this.queuedRender || requestAnimationFrame(() => this.render());
  }

  animate(seconds = 5) {
    this.ticksLeft = this.ticksLeft || 0;
    if (this.ticksLeft <= 0) {
      const interval = setInterval(() => {
        this.ticksLeft -= 1;
        if (this.ticksLeft <= 0) {
          clearInterval(interval);
        }
        this.resize();
      }, 20);
    }
    this.ticksLeft = seconds * 50;
  }
}

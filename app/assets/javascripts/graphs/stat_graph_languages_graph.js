import d3 from 'd3';
import _ from 'underscore';
import graphUtils from './stat_graph_languages_util';

export default class LanguagesGraph {
  constructor(selector, data) {
    this.$rootSvg = document.querySelector(selector);
    this.data = data;
    this.d3RootSvg = d3.select(this.$rootSvg);
    this.updateProps();
    this.bindEvents();
    this.createGraph(true);
  }

  bindEvents() {
    this.windowResizedThrottled = _.bind(_.throttle(this.windowResized, 1000), this);
    window.addEventListener('resize', this.windowResizedThrottled);
  }

  createGraph(transition) {
    this.pie = d3.layout.pie()
    .value(d => d.value);

    const arcPath = d3.svg.arc()
      .outerRadius(this.radius - 10)
      .innerRadius(0);

    const arcs = this.pieContainer.selectAll('.arc')
      .data(this.pie(this.data))
      .enter().append('g')
        .attr('class', 'arc');

    if (transition) {
      arcs.append('path')
      .attr('fill', d => d.data.color)
      .transition().duration(500)
      .attrTween('d', (d) => {
        const data = d;
        const interpolation = d3.interpolate(data.startAngle + 0.1, data.endAngle);
        return function endAnglePath(t) {
          data.endAngle = interpolation(t);
          return arcPath(data);
        };
      });
    } else {
      arcs.append('path')
          .attr('fill', d => d.data.color)
          .attr('d', arcPath);
    }

    arcs.on('mouseover', this.showToolTipWithLabel);
    arcs.on('mouseout', this.showToolTipWithLabel);
  }

  showToolTipWithLabel() {
    console.log('this: ', this);
  }

  hideTooltip() {
    console.log('this: ', this);
  }

  updateProps() {
    this.parentWidth = this.$rootSvg.parentNode.clientWidth - graphUtils.margin.left;
    this.parentHeight = this.$rootSvg.parentNode.clientHeight - graphUtils.margin.top;
    this.radius = Math.min(this.parentWidth, this.parentHeight) / 2;
    this.d3RootSvg.attr('viewBox', `0 0 ${this.parentWidth} ${this.parentHeight}`);
    this.$rootSvg.style.paddingBottom =
      (Math.ceil(this.parentHeight * 100) / this.parentWidth) || 0;
    this.pieContainer = this.d3RootSvg.append('g')
                        .attr('class', 'pie-container')
                        .attr('transform', `translate(${this.parentWidth / 2}, ${this.parentHeight / 2})`);
  }

  windowResized() {
    this.pieContainer.remove();
    this.updateProps();
    this.createGraph();
  }
}

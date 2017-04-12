import d3 from 'd3';

export default class Deployments {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.timeFormat = d3.time.format('%b %d, %Y, %H:%M%p');

    this.endpoint = document.getElementById('js-metrics').dataset.deploymentEndpoint;
  }

  init(chartData) {
    this.chartData = chartData;

    this.x = d3.time.scale().range([0, this.width]);
    this.x.domain(d3.extent(this.chartData, d => d.time));

    this.charts = d3.selectAll('.prometheus-graph .graph-container');

    this.getData();
  }

  getData() {
    $.ajax({
      url: this.endpoint,
      dataType: 'JSON',
    })
    .done((data) => {
      this.data = [];

      data.deployments.forEach((deployment) => {
        const date = new Date(deployment.created_at);

        if (this.x(date) >= 0) {
          this.data.push({
            id: deployment.id,
            time: new Date(deployment.created_at),
            sha: deployment.sha,
            tag: deployment.tag,
            ref: deployment.ref.name,
          });
        }
      });

      this.plotData();
    });
  }

  plotData() {
    this.charts.each((d, i) => {
      const chart = d3.select(this.charts[0][i]);

      this.createLine(chart);
      this.createDeployInfoBox(chart);
    });
  }

  createLine(chart) {
    chart.append('g')
      .attr('class', 'deploy-info')
      .selectAll('.deploy-info')
      .data(this.data)
      .enter()
      .append('g')
      .attr('class', d => `deploy-info-${d.id}`)
      .attr('transform', d => `translate(${Math.floor(this.x(d.time)) + 1}, 0)`)
      .append('line')
      .attr('class', 'deployment-line')
      .attr({
        x1: 0,
        x2: 0,
        y1: 0,
        y2: this.height,
      });
  }

  createDeployInfoBox(chart) {
    this.data.forEach((d) => {
      const group = chart.select(`.deploy-info-${d.id}`)
        .append('svg')
        .attr('x', 3)
        .attr('y', 0)
        .attr('height', 38);

      const rect = group.append('rect')
        .attr('class', 'rect-text-metric deploy-info-rect rect-metric')
        .attr('x', 1)
        .attr('y', 1)
        .attr('rx', 2)
        .attr('height', 35);

      const text = group.append('text')
        .attr('x', 5)
        .attr('y', '50%')
        .attr('style', 'dominant-baseline: middle;')
        .text((d) => {
          const isTag = d.tag;
          const refText = isTag ? d.ref : d.sha.slice(0, 6);

          return `${refText} - ${this.timeFormat(d.time)}`;
        });

      group.attr('width', Math.floor(text.node().getBoundingClientRect().width) + 14);

      rect.attr('width', Math.floor(text.node().getBoundingClientRect().width) + 10);
    });
  }
}

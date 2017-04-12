import d3 from 'd3';

export default class Deployments {
  constructor(width) {
    this.width = width;
    this.timeFormat = d3.time.format('%b %d, %Y, %H:%M%p');
  }

  init(chartData) {
    this.chartData = chartData;

    this.x = d3.time.scale().range([0, this.width]);
    this.x.domain(d3.extent(this.chartData, d => d.time));

    this.getData();
  }

  getData() {
    $.ajax({
      url: 'http://192.168.0.2:3000/root/hello-world/environments/21/deployments',
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
          });
        }
      });

      this.plotData();
    });
  }

  plotData() {
    const charts = d3.selectAll('.prometheus-graph .graph-container');

    charts
      .each((d, i) => {
        const chart = d3.select(charts[0][i]);

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
      .attr('transform', d => `translate(${Math.floor(this.x(d.time)) + 1}, -1)`)
      .append('line')
      .attr('class', 'deployment-line')
      .attr('stroke', '#000000')
      .attr('stroke-width', '2')
      .attr({
        x1: 0,
        x2: 0,
        y1: 0,
        y2: chart.node().getBoundingClientRect().height - 22,
      });
  }

  createDeployInfoBox(chart) {
    this.data.forEach((d) => {
      const group = chart.select(`.deploy-info-${d.id}`)
        .append('svg')
        .attr('class', 'rect-text-metric deploy-info-rect')
        .attr('x', '5')
        .attr('y', '0')
        .attr('width', 100)
        .attr('height', 35);

      group.append('rect')
        .attr('class', 'rect-metric')
        .attr('x', 0)
        .attr('y', 0)
        .attr('rx', 3)
        .attr('width', '100%')
        .attr('height', '100%')

      const text = group.append('text')
        .attr('x', 5)
        .attr('y', '50%')
        .attr('style', 'dominant-baseline: middle;')
        .text((d) => {
          return `${d.sha.slice(0, 6)} - ${this.timeFormat(d.time)}`;
        });

      group.attr('width', Math.floor(text.node().getBoundingClientRect().width) + 10);
    });
  }
}

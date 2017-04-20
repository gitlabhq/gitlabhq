import d3 from 'd3';

export default class Deployments {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.dateFormat = d3.time.format('%b %d, %Y');
    this.timeFormat = d3.time.format('%H:%M%p');

    this.endpoint = document.getElementById('js-metrics').dataset.deploymentEndpoint;

    Deployments.createGradientDef();
  }

  init(chartData) {
    this.chartData = chartData;

    this.x = d3.time.scale().range([0, this.width]);
    this.x.domain(d3.extent(this.chartData, d => d.time));

    this.charts = d3.selectAll('.prometheus-graph');

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
        const minInSeconds = 1000 * 60;
        let time = new Date(deployment.created_at);
        time = new Date(Math.round(time.getTime() / minInSeconds) * minInSeconds);
        time.setSeconds(this.chartData[0].time.getSeconds());
        const xPos = Math.floor(this.x(time));

        if (xPos >= 0) {
          this.data.push({
            id: deployment.id,
            time,
            sha: deployment.sha,
            tag: deployment.tag,
            ref: deployment.ref.name,
            xPos,
          });
        }
      });

      this.plotData();
    });
  }

  plotData() {
    this.charts.each((d, i) => {
      const svg = d3.select(this.charts[0][i]);
      const chart = svg.select('.graph-container');
      const key = svg.node().getAttribute('graph-type');

      this.createLine(chart, key);
      this.createDeployInfoBox(chart, key);
    });
  }

  static createGradientDef() {
    const defs = d3.select('body')
      .append('svg')
      .attr({
        height: 0,
        width: 0,
      })
      .append('defs');

    defs.append('linearGradient')
      .attr({
        id: 'shadow-gradient',
      })
      .append('stop')
      .attr({
        offset: '0%',
        'stop-color': '#000',
        'stop-opacity': 0.4,
      })
      .select(function selectParentNode() {
        return this.parentNode;
      })
      .append('stop')
      .attr({
        offset: '100%',
        'stop-color': '#000',
        'stop-opacity': 0,
      });
  }

  createLine(chart, key) {
    chart.append('g')
      .attr({
        class: 'deploy-info',
      })
      .selectAll('.deploy-info')
      .data(this.data)
      .enter()
      .append('g')
      .attr({
        class: d => `deploy-info-${d.id}-${key}`,
        transform: d => `translate(${Math.floor(d.xPos) + 1}, 0)`,
      })
      .append('rect')
      .attr({
        x: 1,
        y: 0,
        height: this.height + 1,
        width: 3,
        fill: 'url(#shadow-gradient)',
      })
      .select(function selectParentNode() {
        return this.parentNode;
      })
      .append('line')
      .attr({
        class: 'deployment-line',
        x1: 0,
        x2: 0,
        y1: 0,
        y2: this.height + 1,
      });
  }

  createDeployInfoBox(chart, key) {
    this.data.forEach((d) => {
      const group = chart.select(`.deploy-info-${d.id}-${key}`)
        .append('svg')
        .attr({
          x: 3,
          y: 0,
          height: 60,
        });

      const rect = group.append('rect')
        .attr({
          class: 'rect-text-metric deploy-info-rect rect-metric',
          x: 1,
          y: 1,
          rx: 2,
          height: group.attr('height') - 2,
        });

      const textGroup = group.append('g')
        .attr({
          transform: 'translate(5, 2)',
        });

      textGroup.append('text')
        .attr({
          class: 'deploy-info-text text-metric-bold',
        })
        .text(() => {
          const isTag = d.tag;
          const refText = isTag ? d.ref : d.sha.slice(0, 6);

          return refText;
        });

      textGroup.append('text')
        .attr({
          class: 'deploy-info-text',
          y: 18,
        })
        .text(() => this.dateFormat(d.time));

      textGroup.append('text')
        .attr({
          class: 'deploy-info-text text-metric-bold',
          y: 38,
        })
        .text(() => this.timeFormat(d.time));

      group.attr('width', Math.floor(textGroup.node().getBoundingClientRect().width) + 14);

      rect.attr('width', Math.floor(textGroup.node().getBoundingClientRect().width) + 10);

      group.attr('class', 'js-deploy-info-box hidden');
    });
  }

  static toggleDeployTextbox(deploy, key, showInfoBox) {
    d3.selectAll(`.deploy-info-${deploy.id}-${key} .js-deploy-info-box`)
      .classed('hidden', !showInfoBox);
  }

  mouseOverDeployInfo(mouseXPos, key) {
    if (!this.data) return false;

    let dataFound = false;

    this.data.forEach((d) => {
      if (d.xPos >= mouseXPos - 10 && d.xPos <= mouseXPos + 10 && !dataFound) {
        dataFound = d.xPos + 1;

        Deployments.toggleDeployTextbox(d, key, true);
      } else {
        Deployments.toggleDeployTextbox(d, key, false);
      }
    });

    return dataFound;
  }
}

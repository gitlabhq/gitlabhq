import d3 from 'd3';

export default class Deployments {
  constructor(width, height) {
    this.width = width;
    this.height = height;
    this.data = [];
    this.dateFormat = d3.time.format('%b %d, %Y');
    this.timeFormat = d3.time.format('%H:%M%p');

    this.endpoint = document.getElementById('js-metrics').dataset.deploymentEndpoint;

    this.createGradientDef();
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
      data.deployments.forEach((deployment) => {
        const time = new Date(deployment.created_at);
        const xPos = Math.floor(this.x(time));

        time.setSeconds(this.chartData[0].time.getSeconds());

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

  createGradientDef() {
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
      .select(this.selectParentNode)
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
      .select(this.selectParentNode)
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
    chart.selectAll('.deploy-info')
      .selectAll('.js-deploy-info-box')
      .data(this.data)
      .enter()
      .select(d => document.querySelector(`.deploy-info-${d.id}-${key}`))
      .append('svg')
      .attr({
        class: 'js-deploy-info-box hidden',
        x: 3,
        y: 0,
        width: 92,
        height: 60,
      })
      .append('rect')
      .attr({
        class: 'rect-text-metric deploy-info-rect rect-metric',
        x: 1,
        y: 1,
        rx: 2,
        width: 90,
        height: 58,
      })
      .select(this.selectParentNode)
      .append('g')
      .attr({
        transform: 'translate(5, 2)',
      })
      .append('text')
      .attr({
        class: 'deploy-info-text text-metric-bold',
      })
      .text(Deployments.refText)
      .select(this.selectParentNode)
      .append('text')
      .attr({
        class: 'deploy-info-text',
        y: 18,
      })
      .text(d => this.dateFormat(d.time))
      .select(this.selectParentNode)
      .append('text')
      .attr({
        class: 'deploy-info-text text-metric-bold',
        y: 38,
      })
      .text(d => this.timeFormat(d.time));
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

  /* `this` is bound to the D3 node */
  selectParentNode() {
    return this.parentNode;
  }

  static refText(d) {
    const isTag = d.tag;
    const refText = isTag ? d.ref : d.sha.slice(0, 6);

    return refText;
  }
}

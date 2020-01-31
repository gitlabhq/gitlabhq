import $ from 'jquery';
import Chart from 'chart.js';

import { lineChartOptions } from '~/lib/utils/chart_utils';

import initProjectPipelinesChartsApp from '~/projects/pipelines/charts/index';

const SUCCESS_LINE_COLOR = '#1aaa55';

const TOTAL_LINE_COLOR = '#707070';

const buildChart = (chartScope, shouldAdjustFontSize) => {
  const data = {
    labels: chartScope.labels,
    datasets: [
      {
        backgroundColor: SUCCESS_LINE_COLOR,
        borderColor: SUCCESS_LINE_COLOR,
        pointBackgroundColor: SUCCESS_LINE_COLOR,
        pointBorderColor: '#fff',
        data: chartScope.successValues,
        fill: 'origin',
      },
      {
        backgroundColor: TOTAL_LINE_COLOR,
        borderColor: TOTAL_LINE_COLOR,
        pointBackgroundColor: TOTAL_LINE_COLOR,
        pointBorderColor: '#EEE',
        data: chartScope.totalValues,
        fill: '-1',
      },
    ],
  };
  const ctx = $(`#${chartScope.scope}Chart`)
    .get(0)
    .getContext('2d');

  return new Chart(ctx, {
    type: 'line',
    data,
    options: lineChartOptions({
      width: ctx.canvas.width,
      numberOfPoints: chartScope.totalValues.length,
      shouldAdjustFontSize,
    }),
  });
};

document.addEventListener('DOMContentLoaded', () => {
  const chartsData = JSON.parse(document.getElementById('pipelinesChartsData').innerHTML);

  // Scale fonts if window width lower than 768px (iPad portrait)
  const shouldAdjustFontSize = window.innerWidth < 768;

  chartsData.forEach(scope => buildChart(scope, shouldAdjustFontSize));
});

document.addEventListener('DOMContentLoaded', initProjectPipelinesChartsApp);

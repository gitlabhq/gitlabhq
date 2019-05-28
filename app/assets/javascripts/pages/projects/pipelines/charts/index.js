import $ from 'jquery';
import Chart from 'chart.js';

import { barChartOptions, lineChartOptions } from '~/lib/utils/chart_utils';

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

const buildBarChart = (chartTimesData, shouldAdjustFontSize) => {
  const data = {
    labels: chartTimesData.labels,
    datasets: [
      {
        backgroundColor: 'rgba(220,220,220,0.5)',
        borderColor: 'rgba(220,220,220,1)',
        borderWidth: 1,
        barValueSpacing: 1,
        barDatasetSpacing: 1,
        data: chartTimesData.values,
      },
    ],
  };
  return new Chart(
    $('#build_timesChart')
      .get(0)
      .getContext('2d'),
    {
      type: 'bar',
      data,
      options: barChartOptions(shouldAdjustFontSize),
    },
  );
};

document.addEventListener('DOMContentLoaded', () => {
  const chartTimesData = JSON.parse(document.getElementById('pipelinesTimesChartsData').innerHTML);
  const chartsData = JSON.parse(document.getElementById('pipelinesChartsData').innerHTML);

  // Scale fonts if window width lower than 768px (iPad portrait)
  const shouldAdjustFontSize = window.innerWidth < 768;

  buildBarChart(chartTimesData, shouldAdjustFontSize);

  chartsData.forEach(scope => buildChart(scope, shouldAdjustFontSize));
});

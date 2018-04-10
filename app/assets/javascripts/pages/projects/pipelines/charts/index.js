import $ from 'jquery';
import Chart from 'chart.js';

const options = {
  scaleOverlay: true,
  responsive: true,
  maintainAspectRatio: false,
};

const buildChart = (chartScope) => {
  const data = {
    labels: chartScope.labels,
    datasets: [{
      fillColor: '#707070',
      strokeColor: '#707070',
      pointColor: '#707070',
      pointStrokeColor: '#EEE',
      data: chartScope.totalValues,
    },
    {
      fillColor: '#1aaa55',
      strokeColor: '#1aaa55',
      pointColor: '#1aaa55',
      pointStrokeColor: '#fff',
      data: chartScope.successValues,
    },
    ],
  };
  const ctx = $(`#${chartScope.scope}Chart`).get(0).getContext('2d');

  new Chart(ctx).Line(data, options);
};

document.addEventListener('DOMContentLoaded', () => {
  const chartTimesData = JSON.parse(document.getElementById('pipelinesTimesChartsData').innerHTML);
  const chartsData = JSON.parse(document.getElementById('pipelinesChartsData').innerHTML);
  const data = {
    labels: chartTimesData.labels,
    datasets: [{
      fillColor: 'rgba(220,220,220,0.5)',
      strokeColor: 'rgba(220,220,220,1)',
      barStrokeWidth: 1,
      barValueSpacing: 1,
      barDatasetSpacing: 1,
      data: chartTimesData.values,
    }],
  };

  if (window.innerWidth < 768) {
    // Scale fonts if window width lower than 768px (iPad portrait)
    options.scaleFontSize = 8;
  }

  new Chart($('#build_timesChart').get(0).getContext('2d')).Bar(data, options);

  chartsData.forEach(scope => buildChart(scope));
});

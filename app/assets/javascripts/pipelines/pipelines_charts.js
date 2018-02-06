import Chart from 'vendor/Chart';

document.addEventListener('DOMContentLoaded', () => {
  const chartData = JSON.parse(document.getElementById('pipelinesChartsData').innerHTML);
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
    const options = {
      scaleOverlay: true,
      responsive: true,
      maintainAspectRatio: false,
    };
    if (window.innerWidth < 768) {
      // Scale fonts if window width lower than 768px (iPad portrait)
      options.scaleFontSize = 8;
    }
    new Chart(ctx).Line(data, options);
  };

  chartData.forEach(scope => buildChart(scope));
});

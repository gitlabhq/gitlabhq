import Chart from 'vendor/Chart';

document.addEventListener('DOMContentLoaded', () => {
  const chartData = JSON.parse(document.getElementById('pipelinesChartsData').innerHTML);
  const buildChart = (chartScope) => {
    const data = {
      labels: chartScope.labels,
      datasets: [{
        fillColor: '#7f8fa4',
        strokeColor: '#7f8fa4',
        pointColor: '#7f8fa4',
        pointStrokeColor: '#EEE',
        data: chartScope.totalValues,
      },
      {
        fillColor: '#44aa22',
        strokeColor: '#44aa22',
        pointColor: '#44aa22',
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

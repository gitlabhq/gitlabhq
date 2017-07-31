import Chart from 'vendor/Chart';

document.addEventListener('DOMContentLoaded', () => {
  const chartData = JSON.parse(document.getElementById('pipelinesTimesChartsData').innerHTML);
  const data = {
    labels: chartData.labels,
    datasets: [{
      fillColor: 'rgba(220,220,220,0.5)',
      strokeColor: 'rgba(220,220,220,1)',
      barStrokeWidth: 1,
      barValueSpacing: 1,
      barDatasetSpacing: 1,
      data: chartData.values,
    }],
  };
  const ctx = $('#build_timesChart').get(0).getContext('2d');
  const options = {
    scaleOverlay: true,
    responsive: true,
    maintainAspectRatio: false,
  };
  if (window.innerWidth < 768) {
    // Scale fonts if window width lower than 768px (iPad portrait)
    options.scaleFontSize = 8;
  }
  new Chart(ctx).Bar(data, options);
});

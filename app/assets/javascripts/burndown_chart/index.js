import Cookies from 'js-cookie';
import BurndownChart from './burndown_chart';

$(() => {
  // handle hint dismissal
  const hint = $('.burndown-hint');
  hint.on('click', '.dismiss-icon', () => {
    hint.hide();
    Cookies.set('hide_burndown_message', 'true');
  });

  // generate burndown chart (if data available)
  const container = '.burndown-chart';
  const chartElm = $(container);

  if (chartElm.length) {
    const startDate = chartElm.data('startDate');
    const dueDate = chartElm.data('endDate');
    const chartData = chartElm.data('chartData');

    const chart = new BurndownChart({ container, startDate, dueDate });

    chart.setData(chartData, { label: 'Open Issues', animate: true });

    window.addEventListener('resize', () => chart.animateResize(1));
    $(document).on('click', '.js-sidebar-toggle', () => chart.animateResize(2));
  }
});

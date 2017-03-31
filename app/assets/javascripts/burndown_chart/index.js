import Cookies from 'js-cookie';
import BurndownChart from './burndown_chart';
import testData from './test_data.json';

$(() => {
  // handle hint dismissal
  const hint = $('.burndown-hint');
  hint.on('click', '.dismiss-icon', () => {
    hint.hide();
    Cookies.set('hide_burndown_message', 'true');
  });

  // render chart
  const chart = new BurndownChart({
    container: '.burndown-chart',
    startDate: '2017-03-01',
    dueDate: '2017-03-31',
  });

  chart.setData(testData, { label: 'Open Issues', animate: true });
  window.addEventListener('resize', () => chart.animateResize(1));
  $(document).on('click', '.js-sidebar-toggle', () => chart.animateResize(2));
});

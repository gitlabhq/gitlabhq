import $ from 'jquery';
import Cookies from 'js-cookie';
import BurndownChart from './burndown_chart';

export default () => {
  // handle hint dismissal
  const hint = $('.burndown-hint');
  hint.on('click', '.dismiss-icon', () => {
    hint.hide();
    Cookies.set('hide_burndown_message', 'true');
  });

  // generate burndown chart (if data available)
  const container = '.burndown-chart';
  const $chartElm = $(container);

  if ($chartElm.length) {
    const startDate = $chartElm.data('startDate');
    const dueDate = $chartElm.data('dueDate');
    const chartData = $chartElm.data('chartData');
    const openIssuesCount = chartData.map(d => [d[0], d[1]]);
    const openIssuesWeight = chartData.map(d => [d[0], d[2]]);

    const chart = new BurndownChart({ container, startDate, dueDate });

    let currentView = 'count';
    chart.setData(openIssuesCount, { label: 'Open issues', animate: true });

    $('.js-burndown-data-selector').on('click', 'button', function switchData() {
      const $this = $(this);
      const show = $this.data('show');
      if (currentView !== show) {
        currentView = show;
        $this.addClass('active').siblings().removeClass('active');
        switch (show) {
          case 'count':
            chart.setData(openIssuesCount, { label: 'Open issues', animate: true });
            break;
          case 'weight':
            chart.setData(openIssuesWeight, { label: 'Open issue weight', animate: true });
            break;
          default:
            break;
        }
      }
    });

    window.addEventListener('resize', () => chart.animateResize(1));
    $(document).on('click', '.js-sidebar-toggle', () => chart.animateResize(2));
  }
};

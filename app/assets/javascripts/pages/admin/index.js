import initAdminStatisticsPanel from '../../admin/statistics_panel/index';
import initVueAlerts from '../../vue_alerts';
import initAdmin from './admin';

document.addEventListener('DOMContentLoaded', initVueAlerts);

document.addEventListener('DOMContentLoaded', () => {
  const statisticsPanelContainer = document.getElementById('js-admin-statistics-container');
  initAdmin();
  initAdminStatisticsPanel(statisticsPanelContainer);
});

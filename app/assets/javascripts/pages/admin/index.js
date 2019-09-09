import initAdmin from './admin';
import initAdminStatisticsPanel from '../../admin/statistics_panel/index';

document.addEventListener('DOMContentLoaded', () => {
  const statisticsPanelContainer = document.getElementById('js-admin-statistics-container');
  initAdmin();
  initAdminStatisticsPanel(statisticsPanelContainer);
});

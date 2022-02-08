import initGitlabVersionCheck from '~/gitlab_version_check';
import initAdminStatisticsPanel from '../../admin/statistics_panel/index';
import initVueAlerts from '../../vue_alerts';
import initAdmin from './admin';

initVueAlerts();
initGitlabVersionCheck();

const statisticsPanelContainer = document.getElementById('js-admin-statistics-container');
initAdmin();
initAdminStatisticsPanel(statisticsPanelContainer);

import DashboardPage from '../pages/dashboard_page.vue';
import PanelNewPage from '../pages/panel_new_page.vue';

import { DASHBOARD_PAGE, PANEL_NEW_PAGE } from './constants';

/**
 * Because the cluster health page uses the dashboard
 * app instead the of the dashboard component, hitting
 * `/` route is not possible. Hence using `*` until the
 * health page is refactored.
 * https://gitlab.com/gitlab-org/gitlab/-/issues/221096
 */
export default [
  {
    name: PANEL_NEW_PAGE,
    path: '/:dashboard(.+)?/panel/new',
    component: PanelNewPage,
  },
  {
    name: DASHBOARD_PAGE,
    path: '/:dashboard(.+)?',
    component: DashboardPage,
  },
];

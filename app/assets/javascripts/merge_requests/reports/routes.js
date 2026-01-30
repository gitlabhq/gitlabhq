import BlockersPage from 'ee_else_ce/merge_requests/reports/pages/blockers_page.vue';
import IndexComponent from './pages/index.vue';
import { BLOCKERS_ROUTE, SECURITY_ROUTE } from './constants';

export default [
  {
    path: '/',
    name: BLOCKERS_ROUTE,
    component: BlockersPage,
  },
  {
    name: SECURITY_ROUTE,
    path: `/${SECURITY_ROUTE}`,
    component: () => import('ee_component/merge_requests/reports/pages/security_findings_page.vue'),
  },
  {
    name: 'report',
    path: '/:report',
    component: IndexComponent,
  },
];

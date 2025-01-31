import BlockersPage from 'ee_else_ce/merge_requests/reports/pages/blockers_page.vue';
import IndexComponent from './pages/index.vue';
import { BLOCKERS_ROUTE } from './constants';

export default [
  {
    path: '/',
    name: BLOCKERS_ROUTE,
    component: BlockersPage,
  },
  {
    name: 'report',
    path: '/:report',
    component: IndexComponent,
  },
];

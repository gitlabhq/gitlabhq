import BlockersPage from 'ee_else_ce/merge_requests/reports/pages/blockers_page.vue';
import IndexComponent from './pages/index.vue';
import {
  BLOCKERS_ROUTE,
  CODE_QUALITY_ROUTE,
  LICENSE_COMPLIANCE_ROUTE,
  SECURITY_ROUTE,
} from './constants';

export default [
  {
    path: '/',
    name: BLOCKERS_ROUTE,
    component: BlockersPage,
  },
  {
    path: '/?type=code-quality',
    name: CODE_QUALITY_ROUTE,
    component: IndexComponent,
  },
  {
    path: '/?type=security',
    name: SECURITY_ROUTE,
    component: IndexComponent,
  },
  {
    path: '/?type=license-compliance',
    name: LICENSE_COMPLIANCE_ROUTE,
    component: IndexComponent,
  },
];

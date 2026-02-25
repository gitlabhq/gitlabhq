import { SECURITY_SCAN_ROUTE } from './constants';

export default [
  {
    path: '/',
    redirect: { name: SECURITY_SCAN_ROUTE },
  },
  {
    name: SECURITY_SCAN_ROUTE,
    path: `/${SECURITY_SCAN_ROUTE}`,
    component: () => import('ee_component/merge_requests/reports/pages/security_scans_page.vue'),
  },
];

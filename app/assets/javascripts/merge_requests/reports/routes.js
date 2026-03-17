import { SECURITY_SCAN_ROUTE, LICENSE_COMPLIANCE_ROUTE, CODE_QUALITY_ROUTE } from './constants';

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
  {
    name: LICENSE_COMPLIANCE_ROUTE,
    path: `/${LICENSE_COMPLIANCE_ROUTE}`,
    component: () =>
      import('ee_component/merge_requests/reports/pages/license_compliance_page.vue'),
  },
  {
    name: CODE_QUALITY_ROUTE,
    path: `/${CODE_QUALITY_ROUTE}`,
    component: () => import('~/merge_requests/reports/pages/code_quality_page.vue'),
  },
];

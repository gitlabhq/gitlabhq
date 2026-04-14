import { SECURITY_SCAN_ROUTE, LICENSE_COMPLIANCE_ROUTE, CODE_QUALITY_ROUTE } from './constants';

const CATCH_ALL_ROUTE = '/:pathMatch(.*)*';

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
  {
    path: CATCH_ALL_ROUTE,
    component: { render: () => null },
    beforeEnter(to, from, next) {
      // The MR page has two navigation systems: MR Tabs (merge_request_tabs.js)
      // and Vue Router. Both listen to the browser's Back button. When the user
      // presses Back to leave the Reports tab, Vue Router sees a URL it doesn't
      // recognize, which causes unexpected navigation behaviour. This catch-all
      // cancels the navigation and lets MR Tabs handle it.
      const currentUrl = window.location.href;
      next(false);
      window.history.replaceState(null, null, currentUrl);
    },
  },
];

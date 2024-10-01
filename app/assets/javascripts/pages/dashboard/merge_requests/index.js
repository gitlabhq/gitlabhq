import { initMergeRequestsDashboard } from './page';

const el = document.getElementById('js-merge-request-dashboard');

if (el) {
  requestIdleCallback(async () => {
    const { initMergeRequestDashboard } = await import('~/merge_request_dashboard');

    initMergeRequestDashboard(el);
  });
} else {
  initMergeRequestsDashboard();
}

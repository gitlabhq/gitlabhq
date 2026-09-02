import { initMergeRequestDashboard } from '~/merge_request_dashboard';
import { initMergeRequestsDashboard } from '../merge_requests/page';

const el = document.getElementById('js-merge-request-dashboard');

if (el) {
  initMergeRequestDashboard(el);
} else {
  initMergeRequestsDashboard();
}

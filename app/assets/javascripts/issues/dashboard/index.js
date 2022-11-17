import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import IssuesDashboardApp from './components/issues_dashboard_app.vue';

export function mountIssuesDashboardApp() {
  const el = document.querySelector('.js-issues-dashboard');

  if (!el) {
    return null;
  }

  const { calendarPath, emptyStateSvgPath, isSignedIn, rssPath } = el.dataset;

  return new Vue({
    el,
    name: 'IssuesDashboardRoot',
    provide: {
      calendarPath,
      emptyStateSvgPath,
      isSignedIn: parseBoolean(isSignedIn),
      rssPath,
    },
    render: (createComponent) => createComponent(IssuesDashboardApp),
  });
}

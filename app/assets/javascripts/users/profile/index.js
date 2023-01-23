import Vue from 'vue';
import ReportAbuseButton from './components/report_abuse_button.vue';

export const initReportAbuse = () => {
  const el = document.getElementById('js-report-abuse');

  if (!el) return false;

  const { reportAbusePath, reportedUserId, reportedFromUrl } = el.dataset;

  return new Vue({
    el,
    name: 'ReportAbuseButtonRoot',
    provide: {
      reportAbusePath,
      reportedUserId: parseInt(reportedUserId, 10),
      reportedFromUrl,
    },
    render(createElement) {
      return createElement(ReportAbuseButton);
    },
  });
};

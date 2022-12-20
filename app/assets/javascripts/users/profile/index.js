import Vue from 'vue';
import ReportAbuseButton from './components/report_abuse_button.vue';

export const initReportAbuse = () => {
  const el = document.getElementById('js-report-abuse');

  if (!el) return false;

  const { formSubmitPath, userId, reportedFromUrl } = el.dataset;

  return new Vue({
    el,
    provide: { formSubmitPath, userId, reportedFromUrl },
    render(createElement) {
      return createElement(ReportAbuseButton);
    },
  });
};

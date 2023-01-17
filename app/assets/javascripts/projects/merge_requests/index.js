import Vue from 'vue';
import ReportAbuseDropdownItem from './components/report_abuse_dropdown_item.vue';

export const initReportAbuse = () => {
  const el = document.getElementById('js-report-abuse-dropdown-item');

  if (!el) return false;

  const { reportAbusePath, reportedUserId, reportedFromUrl } = el.dataset;

  return new Vue({
    el,
    provide: { reportAbusePath, reportedUserId, reportedFromUrl },
    render(createElement) {
      return createElement(ReportAbuseDropdownItem);
    },
  });
};

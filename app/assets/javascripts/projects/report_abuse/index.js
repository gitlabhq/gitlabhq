import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ReportAbuseDropdownItem from './components/report_abuse_dropdown_item.vue';

export const initReportAbuse = () => {
  const items = document.querySelectorAll('.js-report-abuse-dropdown-item');

  items.forEach((el) => {
    if (!el) return false;

    const { reportAbusePath, reportedUserId, reportedFromUrl } = el.dataset;

    return initVueApp({
      el,
      name: 'ReportAbuseDropdownItemRoot',
      provide: {
        reportAbusePath,
        reportedUserId: parseInt(reportedUserId, 10),
        reportedFromUrl,
      },
      component: ReportAbuseDropdownItem,
    });
  });
};

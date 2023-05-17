import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AbuseReportApp from './components/abuse_report_app.vue';

export const initAbuseReportApp = () => {
  const el = document.querySelector('#js-abuse-reports-detail-view');

  if (!el) {
    return null;
  }

  const { abuseReportData } = el.dataset;
  const abuseReport = convertObjectPropsToCamelCase(JSON.parse(abuseReportData), {
    deep: true,
  });

  return new Vue({
    el,
    name: 'AbuseReportAppRoot',
    render: (createElement) =>
      createElement(AbuseReportApp, {
        props: {
          abuseReport,
        },
      }),
  });
};

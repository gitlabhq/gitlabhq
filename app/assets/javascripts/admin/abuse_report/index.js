import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { defaultClient } from '~/graphql_shared/issuable_client';
import AbuseReportApp from './components/abuse_report_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
});

export const initAbuseReportApp = () => {
  const el = document.querySelector('#js-abuse-reports-detail-view');

  if (!el) {
    return null;
  }

  const { abuseReportData, abuseReportsListPath } = el.dataset;
  const abuseReport = convertObjectPropsToCamelCase(JSON.parse(abuseReportData), {
    deep: true,
  });

  return initVueApp({
    el,
    apolloProvider,
    name: 'AbuseReportAppRoot',
    provide: {
      allowScopedLabels: false,
      updatePath: abuseReport.report.updatePath,
      listPath: abuseReportsListPath,
    },
    component: AbuseReportApp,
    props: {
      abuseReport,
    },
  });
};

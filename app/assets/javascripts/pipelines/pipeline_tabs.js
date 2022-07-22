import Vue from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import PipelineTabs from 'ee_else_ce/pipelines/components/pipeline_tabs.vue';
import { removeParams, updateHistory } from '~/lib/utils/url_utility';
import { TAB_QUERY_PARAM } from '~/pipelines/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getPipelineDefaultTab, reportToSentry } from './utils';

Vue.use(VueApollo);
Vue.use(Vuex);

export const createAppOptions = (selector, apolloProvider) => {
  const el = document.querySelector(selector);

  if (!el) return null;

  const { dataset } = el;
  const {
    canGenerateCodequalityReports,
    codequalityReportDownloadPath,
    downloadablePathForReportType,
    exposeSecurityDashboard,
    exposeLicenseScanningData,
    failedJobsCount,
    failedJobsSummary,
    fullPath,
    graphqlResourceEtag,
    pipelineIid,
    pipelineProjectPath,
    totalJobCount,
    licenseManagementApiUrl,
    licenseManagementSettingsPath,
    licensesApiPath,
    canManageLicenses,
  } = dataset;

  const defaultTabValue = getPipelineDefaultTab(window.location.href);

  return {
    el,
    components: {
      PipelineTabs,
    },
    apolloProvider,
    store: new Vuex.Store(),
    provide: {
      canGenerateCodequalityReports: parseBoolean(canGenerateCodequalityReports),
      codequalityReportDownloadPath,
      defaultTabValue,
      downloadablePathForReportType,
      exposeSecurityDashboard: parseBoolean(exposeSecurityDashboard),
      exposeLicenseScanningData: parseBoolean(exposeLicenseScanningData),
      failedJobsCount,
      failedJobsSummary: JSON.parse(failedJobsSummary),
      fullPath,
      graphqlResourceEtag,
      pipelineIid,
      pipelineProjectPath,
      totalJobCount,
      licenseManagementApiUrl,
      licenseManagementSettingsPath,
      licensesApiPath,
      canManageLicenses: parseBoolean(canManageLicenses),
    },
    errorCaptured(err, _vm, info) {
      reportToSentry('pipeline_tabs', `error: ${err}, info: ${info}`);
    },
    render(createElement) {
      return createElement(PipelineTabs);
    },
  };
};

export const createPipelineTabs = (options) => {
  if (!options) return;

  updateHistory({
    url: removeParams([TAB_QUERY_PARAM]),
    title: document.title,
    replace: true,
  });

  // eslint-disable-next-line no-new
  new Vue(options);
};

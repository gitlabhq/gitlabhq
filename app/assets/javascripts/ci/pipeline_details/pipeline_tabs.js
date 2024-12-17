import Vue from 'vue';
import VueRouter from 'vue-router';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import PipelineTabs from 'ee_else_ce/ci/pipeline_details/tabs/pipeline_tabs.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import createTestReportsStore from './stores/test_reports';
import { getPipelineDefaultTab } from './utils';

Vue.use(GlToast);
Vue.use(VueApollo);
Vue.use(VueRouter);
Vue.use(Vuex);

export const createAppOptions = (selector, apolloProvider, router) => {
  const el = document.querySelector(selector);

  if (!el) return null;

  const { dataset } = el;
  const {
    canGenerateCodequalityReports,
    codequalityReportDownloadPath,
    codequalityBlobPath,
    codequalityProjectPath,
    downloadablePathForReportType,
    exposeSecurityDashboard,
    exposeLicenseScanningData,
    failedJobsCount,
    projectPath,
    graphqlResourceEtag,
    pipelineIid,
    pipelineProjectPath,
    totalJobCount,
    licenseManagementApiUrl,
    licenseScanCount,
    licensesApiPath,
    canManageLicenses,
    summaryEndpoint,
    suiteEndpoint,
    blobPath,
    hasTestReport,
    emptyStateImagePath,
    artifactsExpiredImagePath,
    isFullCodequalityReportAvailable,
    securityPoliciesPath,
    testsCount,
    manualVariablesCount,
    canReadVariables,
  } = dataset;

  const defaultTabValue = getPipelineDefaultTab(window.location.href);

  return {
    el,
    components: {
      PipelineTabs,
    },
    apolloProvider,
    store: new Vuex.Store({
      modules: {
        testReports: createTestReportsStore({
          blobPath,
          summaryEndpoint,
          suiteEndpoint,
        }),
      },
    }),
    router,
    provide: {
      canGenerateCodequalityReports: parseBoolean(canGenerateCodequalityReports),
      codequalityReportDownloadPath,
      codequalityBlobPath,
      codequalityProjectPath,
      isFullCodequalityReportAvailable: parseBoolean(isFullCodequalityReportAvailable),
      projectPath,
      defaultTabValue,
      downloadablePathForReportType,
      exposeSecurityDashboard: parseBoolean(exposeSecurityDashboard),
      exposeLicenseScanningData: parseBoolean(exposeLicenseScanningData),
      failedJobsCount,
      graphqlResourceEtag,
      pipelineIid,
      pipelineProjectPath,
      totalJobCount,
      licenseManagementApiUrl,
      licenseScanCount,
      licensesApiPath,
      canManageLicenses: parseBoolean(canManageLicenses),
      summaryEndpoint,
      suiteEndpoint,
      blobPath,
      hasTestReport,
      emptyStateImagePath,
      artifactsExpiredImagePath,
      securityPoliciesPath,
      testsCount,
      manualVariablesCount: Number.parseInt(manualVariablesCount, 10),
      canReadVariables: parseBoolean(canReadVariables),
    },
    render(createElement, props = {}) {
      return createElement(PipelineTabs, { props });
    },
  };
};

export const createPipelineTabs = (options) => {
  if (!options) return;

  // eslint-disable-next-line no-new
  new Vue(options);
};

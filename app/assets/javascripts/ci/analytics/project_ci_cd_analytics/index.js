import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import ProjectPipelinesCharts from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initProjectCiCdAnalytics = () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  if (!el) {
    return null;
  }

  const { projectPath, failedPipelinesLink, coverageChartPath, defaultBranch } = el.dataset;

  const shouldRenderQualitySummary = parseBoolean(el.dataset.shouldRenderQualitySummary);
  const clickHouseEnabledForAnalytics = parseBoolean(el.dataset.clickHouseEnabledForAnalytics);
  const projectBranchCount = parseInt(el.dataset.projectBranchCount, 10);

  return initVueApp({
    el,
    name: 'ProjectPipelinesChartsApp',
    component: ProjectPipelinesCharts,
    apolloProvider,
    provide: {
      projectPath,
      failedPipelinesLink,
      shouldRenderQualitySummary,
      clickHouseEnabledForAnalytics,
      coverageChartPath,
      defaultBranch,
      projectBranchCount,
    },
  });
};

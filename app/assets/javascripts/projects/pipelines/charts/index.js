import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import ProjectPipelinesCharts from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const mountPipelineChartsApp = (el) => {
  const {
    projectId,
    projectPath,
    failedPipelinesLink,
    coverageChartPath,
    defaultBranch,
    testRunsEmptyStateImagePath,
    projectQualitySummaryFeedbackImagePath,
  } = el.dataset;

  const shouldRenderDoraCharts = parseBoolean(el.dataset.shouldRenderDoraCharts);
  const shouldRenderQualitySummary = parseBoolean(el.dataset.shouldRenderQualitySummary);
  const contextId = convertToGraphQLId(TYPENAME_PROJECT, projectId);

  return new Vue({
    el,
    name: 'ProjectPipelinesChartsApp',
    components: {
      ProjectPipelinesCharts,
    },
    apolloProvider,
    provide: {
      projectPath,
      failedPipelinesLink,
      shouldRenderDoraCharts,
      shouldRenderQualitySummary,
      coverageChartPath,
      defaultBranch,
      testRunsEmptyStateImagePath,
      projectQualitySummaryFeedbackImagePath,
      contextId,
    },
    render: (createElement) => createElement(ProjectPipelinesCharts, {}),
  });
};

export default () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  return !el ? {} : mountPipelineChartsApp(el);
};

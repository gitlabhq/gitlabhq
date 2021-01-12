import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectPipelinesChartsLegacy from './components/app_legacy.vue';
import ProjectPipelinesCharts from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const mountPipelineChartsApp = (el) => {
  // Not all of the values will be defined since some them will be
  // empty depending on the value of the graphql_pipeline_analytics
  // feature flag, once the rollout of the feature flag is completed
  // the undefined values will be deleted
  const {
    countsFailed,
    countsSuccess,
    countsTotal,
    countsTotalDuration,
    successRatio,
    timesChartLabels,
    timesChartValues,
    lastWeekChartLabels,
    lastWeekChartTotals,
    lastWeekChartSuccess,
    lastMonthChartLabels,
    lastMonthChartTotals,
    lastMonthChartSuccess,
    lastYearChartLabels,
    lastYearChartTotals,
    lastYearChartSuccess,
    projectPath,
  } = el.dataset;

  const shouldRenderDeploymentFrequencyCharts = parseBoolean(
    el.dataset.shouldRenderDeploymentFrequencyCharts,
  );

  const parseAreaChartData = (labels, totals, success) => {
    let parsedData = {};

    try {
      parsedData = {
        labels: JSON.parse(labels),
        totals: JSON.parse(totals),
        success: JSON.parse(success),
      };
    } catch {
      parsedData = {};
    }

    return parsedData;
  };

  if (gon?.features?.graphqlPipelineAnalytics) {
    return new Vue({
      el,
      name: 'ProjectPipelinesChartsApp',
      components: {
        ProjectPipelinesCharts,
      },
      apolloProvider,
      provide: {
        projectPath,
        shouldRenderDeploymentFrequencyCharts,
      },
      render: (createElement) => createElement(ProjectPipelinesCharts, {}),
    });
  }

  return new Vue({
    el,
    name: 'ProjectPipelinesChartsAppLegacy',
    components: {
      ProjectPipelinesChartsLegacy,
    },
    provide: {
      projectPath,
      shouldRenderDeploymentFrequencyCharts,
    },
    render: (createElement) =>
      createElement(ProjectPipelinesChartsLegacy, {
        props: {
          counts: {
            failed: countsFailed,
            success: countsSuccess,
            total: countsTotal,
            successRatio,
            totalDuration: countsTotalDuration,
          },
          timesChartData: {
            labels: JSON.parse(timesChartLabels),
            values: JSON.parse(timesChartValues),
          },
          lastWeekChartData: parseAreaChartData(
            lastWeekChartLabels,
            lastWeekChartTotals,
            lastWeekChartSuccess,
          ),
          lastMonthChartData: parseAreaChartData(
            lastMonthChartLabels,
            lastMonthChartTotals,
            lastMonthChartSuccess,
          ),
          lastYearChartData: parseAreaChartData(
            lastYearChartLabels,
            lastYearChartTotals,
            lastYearChartSuccess,
          ),
        },
      }),
  });
};

export default () => {
  const el = document.querySelector('#js-project-pipelines-charts-app');
  return !el ? {} : mountPipelineChartsApp(el);
};

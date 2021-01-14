import { shallowMount } from '@vue/test-utils';
import Component from '~/projects/pipelines/charts/components/app_legacy.vue';
import PipelineCharts from '~/projects/pipelines/charts/components/pipeline_charts.vue';
import {
  counts,
  timesChartData,
  areaChartData as lastWeekChartData,
  areaChartData as lastMonthChartData,
  lastYearChartData,
} from '../mock_data';

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        counts,
        timesChartData,
        lastWeekChartData,
        lastMonthChartData,
        lastYearChartData,
      },
      provide: {
        projectPath: 'test/project',
        shouldRenderDeploymentFrequencyCharts: true,
      },
      stubs: {
        DeploymentFrequencyCharts: true,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('pipelines charts', () => {
    it('displays the pipeline charts', () => {
      const chart = wrapper.find(PipelineCharts);

      expect(chart.exists()).toBe(true);
      expect(chart.props()).toMatchObject({
        counts,
        lastWeek: lastWeekChartData,
        lastMonth: lastMonthChartData,
        lastYear: lastYearChartData,
        timesChart: timesChartData,
      });
    });
  });
});

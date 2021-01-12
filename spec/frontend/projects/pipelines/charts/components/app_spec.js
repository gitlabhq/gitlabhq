import { merge } from 'lodash';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import Component from '~/projects/pipelines/charts/components/app.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import CiCdAnalyticsAreaChart from '~/projects/pipelines/charts/components/ci_cd_analytics_area_chart.vue';
import getPipelineCountByStatus from '~/projects/pipelines/charts/graphql/queries/get_pipeline_count_by_status.query.graphql';
import getProjectPipelineStatistics from '~/projects/pipelines/charts/graphql/queries/get_project_pipeline_statistics.query.graphql';
import { mockPipelineCount, mockPipelineStatistics } from '../mock_data';

const projectPath = 'gitlab-org/gitlab';
const localVue = createLocalVue();
localVue.use(VueApollo);

const DeploymentFrequencyChartsStub = { name: 'DeploymentFrequencyCharts', render: () => {} };

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  function createMockApolloProvider() {
    const requestHandlers = [
      [getPipelineCountByStatus, jest.fn().mockResolvedValue(mockPipelineCount)],
      [getProjectPipelineStatistics, jest.fn().mockResolvedValue(mockPipelineStatistics)],
    ];

    return createMockApollo(requestHandlers);
  }

  function createComponent(mountOptions = {}) {
    wrapper = shallowMount(
      Component,
      merge(
        {},
        {
          provide: {
            projectPath,
            shouldRenderDeploymentFrequencyCharts: false,
          },
          localVue,
          apolloProvider: createMockApolloProvider(),
          stubs: {
            DeploymentFrequencyCharts: DeploymentFrequencyChartsStub,
          },
        },
        mountOptions,
      ),
    );
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('overall statistics', () => {
    it('displays the statistics list', () => {
      const list = wrapper.find(StatisticsList);

      expect(list.exists()).toBe(true);
      expect(list.props('counts')).toMatchObject({
        failed: 1,
        success: 23,
        total: 34,
        successRatio: 95.83333333333334,
      });
    });

    it('displays the commit duration chart', () => {
      const chart = wrapper.find(GlColumnChart);

      expect(chart.exists()).toBe(true);
      expect(chart.props('yAxisTitle')).toBe('Minutes');
      expect(chart.props('xAxisTitle')).toBe('Commit');
      expect(chart.props('bars')).toBe(wrapper.vm.timesChartTransformedData);
      expect(chart.props('option')).toBe(wrapper.vm.$options.timesChartOptions);
    });
  });

  describe('pipelines charts', () => {
    it('displays 3 area charts', () => {
      expect(wrapper.findAll(CiCdAnalyticsAreaChart)).toHaveLength(3);
    });

    describe('displays individual correctly', () => {
      it('renders with the correct data', () => {
        const charts = wrapper.findAll(CiCdAnalyticsAreaChart);

        for (let i = 0; i < charts.length; i += 1) {
          const chart = charts.at(i);

          expect(chart.exists()).toBe(true);
          // TODO: Refactor this to use the mocked data instead of the vm data
          // https://gitlab.com/gitlab-org/gitlab/-/issues/292085
          expect(chart.props('chartData')).toBe(wrapper.vm.areaCharts[i].data);
          expect(chart.text()).toBe(wrapper.vm.areaCharts[i].title);
        }
      });
    });
  });

  const findDeploymentFrequencyCharts = () => wrapper.find(DeploymentFrequencyChartsStub);

  describe('when shouldRenderDeploymentFrequencyCharts is true', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderDeploymentFrequencyCharts: true } });
    });

    it('renders the deployment frequency charts', () => {
      expect(findDeploymentFrequencyCharts().exists()).toBe(true);
    });
  });

  describe('when shouldRenderDeploymentFrequencyCharts is false', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderDeploymentFrequencyCharts: false } });
    });

    it('does not render the deployment frequency charts', () => {
      expect(findDeploymentFrequencyCharts().exists()).toBe(false);
    });
  });
});

import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import metricsData from 'test_fixtures/projects/analytics/value_stream_analytics/summary.json';
import waitForPromises from 'helpers/wait_for_promises';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import { METRICS_POPOVER_CONTENT } from '~/analytics/shared/constants';
import { prepareTimeMetricsData } from '~/analytics/shared/utils';
import MetricTile from '~/analytics/shared/components/metric_tile.vue';
import createFlash from '~/flash';
import { group } from './mock_data';

jest.mock('~/flash');

describe('ValueStreamMetrics', () => {
  let wrapper;
  let mockGetValueStreamSummaryMetrics;
  let mockFilterFn;

  const { full_path: requestPath } = group;
  const fakeReqName = 'Mock metrics';
  const metricsRequestFactory = () => ({
    request: mockGetValueStreamSummaryMetrics,
    endpoint: METRIC_TYPE_SUMMARY,
    name: fakeReqName,
  });

  const createComponent = (props = {}) => {
    return shallowMount(ValueStreamMetrics, {
      propsData: {
        requestPath,
        requestParams: {},
        requests: [metricsRequestFactory()],
        ...props,
      },
    });
  };

  const findMetrics = () => wrapper.findAllComponents(MetricTile);

  const expectToHaveRequest = (fields) => {
    expect(mockGetValueStreamSummaryMetrics).toHaveBeenCalledWith({
      endpoint: METRIC_TYPE_SUMMARY,
      requestPath,
      ...fields,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with successful requests', () => {
    beforeEach(() => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
      wrapper = createComponent();
    });

    it('will display a loader with pending requests', async () => {
      await nextTick();

      expect(wrapper.findComponent(GlSkeletonLoading).exists()).toBe(true);
    });

    it('renders hidden MetricTile components for each metric', async () => {
      await waitForPromises();

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({ isLoading: true });

      await nextTick();

      const components = findMetrics();

      expect(components).toHaveLength(metricsData.length);

      metricsData.forEach((metric, index) => {
        expect(components.at(index).isVisible()).toBe(false);
      });
    });

    describe('with data loaded', () => {
      beforeEach(async () => {
        await waitForPromises();
      });

      it('fetches data from the value stream analytics endpoint', () => {
        expectToHaveRequest({ params: {} });
      });

      describe.each`
        index | identifier                   | value                   | label
        ${0}  | ${metricsData[0].identifier} | ${metricsData[0].value} | ${metricsData[0].title}
        ${1}  | ${metricsData[1].identifier} | ${metricsData[1].value} | ${metricsData[1].title}
        ${2}  | ${metricsData[2].identifier} | ${metricsData[2].value} | ${metricsData[2].title}
        ${3}  | ${metricsData[3].identifier} | ${metricsData[3].value} | ${metricsData[3].title}
      `('metric tiles', ({ identifier, index, value, label }) => {
        it(`renders a metric tile component for "${label}"`, () => {
          const metric = findMetrics().at(index);
          expect(metric.props('metric')).toMatchObject({ identifier, value, label });
          expect(metric.isVisible()).toBe(true);
        });
      });

      it('will not display a loading icon', () => {
        expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);
      });

      describe('filterFn', () => {
        const transferredMetricsData = prepareTimeMetricsData(metricsData, METRICS_POPOVER_CONTENT);

        it('with a filter function, will call the function with the metrics data', async () => {
          const filteredData = [
            { identifier: 'issues', value: '3', title: 'New Issues', description: 'foo' },
          ];
          mockFilterFn = jest.fn(() => filteredData);

          wrapper = createComponent({
            filterFn: mockFilterFn,
          });

          await waitForPromises();

          expect(mockFilterFn).toHaveBeenCalledWith(transferredMetricsData);
          expect(wrapper.vm.metrics).toEqual(filteredData);
        });

        it('without a filter function, it will only update the metrics', async () => {
          wrapper = createComponent();

          await waitForPromises();

          expect(mockFilterFn).not.toHaveBeenCalled();
          expect(wrapper.vm.metrics).toEqual(transferredMetricsData);
        });
      });

      describe('with additional params', () => {
        beforeEach(async () => {
          wrapper = createComponent({
            requestParams: {
              'project_ids[]': [1],
              created_after: '2020-01-01',
              created_before: '2020-02-01',
            },
          });

          await waitForPromises();
        });

        it('fetches data for the `getValueStreamSummaryMetrics` request', () => {
          expectToHaveRequest({
            params: {
              'project_ids[]': [1],
              created_after: '2020-01-01',
              created_before: '2020-02-01',
            },
          });
        });
      });
    });
  });

  describe('with a request failing', () => {
    beforeEach(async () => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockRejectedValue();
      wrapper = createComponent();

      await waitForPromises();
    });

    it('it should render an error message', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: `There was an error while fetching value stream analytics ${fakeReqName} data.`,
      });
    });
  });
});

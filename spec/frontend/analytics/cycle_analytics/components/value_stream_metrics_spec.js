import { GlSkeletonLoader } from '@gitlab/ui';
import { nextTick } from 'vue';
import metricsData from 'test_fixtures/projects/analytics/value_stream_analytics/summary.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import { VSA_METRICS_GROUPS, METRICS_POPOVER_CONTENT } from '~/analytics/shared/constants';
import { prepareTimeMetricsData } from '~/analytics/shared/utils';
import MetricTile from '~/analytics/shared/components/metric_tile.vue';
import ValueStreamsDashboardLink from '~/analytics/shared/components/value_streams_dashboard_link.vue';
import { createAlert } from '~/alert';
import { group } from '../mock_data';

jest.mock('~/alert');

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
    return shallowMountExtended(ValueStreamMetrics, {
      propsData: {
        requestPath,
        requestParams: {},
        requests: [metricsRequestFactory()],
        ...props,
      },
    });
  };

  const findVSDLink = () => wrapper.findComponent(ValueStreamsDashboardLink);
  const findMetrics = () => wrapper.findAllComponents(MetricTile);
  const findMetricsGroups = () => wrapper.findAllByTestId('vsa-metrics-group');

  const expectToHaveRequest = (fields) => {
    expect(mockGetValueStreamSummaryMetrics).toHaveBeenCalledWith({
      endpoint: METRIC_TYPE_SUMMARY,
      requestPath,
      ...fields,
    });
  };

  describe('with successful requests', () => {
    beforeEach(() => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
    });

    it('will display a loader with pending requests', async () => {
      wrapper = createComponent();
      await nextTick();

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    describe('with data loaded', () => {
      beforeEach(async () => {
        wrapper = createComponent();
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
        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
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

      describe('groupBy', () => {
        beforeEach(async () => {
          mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
          wrapper = createComponent({ groupBy: VSA_METRICS_GROUPS });
          await waitForPromises();
        });

        it('renders the metrics as separate groups', () => {
          const groups = findMetricsGroups();
          expect(groups).toHaveLength(VSA_METRICS_GROUPS.length);
        });

        it('renders titles for each group', () => {
          const groups = findMetricsGroups();
          groups.wrappers.forEach((g, index) => {
            const { title } = VSA_METRICS_GROUPS[index];
            expect(g.html()).toContain(title);
          });
        });
      });
    });
  });

  describe('Value Streams Dashboard Link', () => {
    it('will render when a dashboardsPath is set', async () => {
      wrapper = createComponent({ groupBy: VSA_METRICS_GROUPS, dashboardsPath: 'fake-group-path' });
      await waitForPromises();

      const vsdLink = findVSDLink();

      expect(vsdLink.exists()).toBe(true);
      expect(vsdLink.props()).toEqual({ requestPath: 'fake-group-path' });
    });

    it('does not render without a dashboardsPath', async () => {
      wrapper = createComponent({ groupBy: VSA_METRICS_GROUPS });
      await waitForPromises();

      expect(findVSDLink().exists()).toBe(false);
    });
  });

  describe('with a request failing', () => {
    beforeEach(async () => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockRejectedValue();
      wrapper = createComponent();

      await waitForPromises();
    });

    it('should render an error message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: `There was an error while fetching value stream analytics ${fakeReqName} data.`,
      });
    });
  });
});

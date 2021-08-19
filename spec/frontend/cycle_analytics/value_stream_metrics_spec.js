import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import createFlash from '~/flash';
import { group, metricsData } from './mock_data';

jest.mock('~/flash');

describe('ValueStreamMetrics', () => {
  let wrapper;
  let mockGetValueStreamSummaryMetrics;

  const { full_path: requestPath } = group;
  const fakeReqName = 'Mock metrics';
  const metricsRequestFactory = () => ({
    request: mockGetValueStreamSummaryMetrics,
    endpoint: METRIC_TYPE_SUMMARY,
    name: fakeReqName,
  });

  const createComponent = ({ requestParams = {} } = {}) => {
    return shallowMount(ValueStreamMetrics, {
      propsData: {
        requestPath,
        requestParams,
        requests: [metricsRequestFactory()],
      },
    });
  };

  const findMetrics = () => wrapper.findAllComponents(GlSingleStat);

  const expectToHaveRequest = (fields) => {
    expect(mockGetValueStreamSummaryMetrics).toHaveBeenCalledWith({
      endpoint: METRIC_TYPE_SUMMARY,
      requestPath,
      ...fields,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with successful requests', () => {
    beforeEach(() => {
      mockGetValueStreamSummaryMetrics = jest.fn().mockResolvedValue({ data: metricsData });
      wrapper = createComponent();
    });

    it('will display a loader with pending requests', async () => {
      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlSkeletonLoading).exists()).toBe(true);
    });

    describe('with data loaded', () => {
      beforeEach(async () => {
        await waitForPromises();
      });

      it('fetches data from the value stream analytics endpoint', () => {
        expectToHaveRequest({ params: {} });
      });

      it.each`
        index | value                   | title                   | unit
        ${0}  | ${metricsData[0].value} | ${metricsData[0].title} | ${metricsData[0].unit}
        ${1}  | ${metricsData[1].value} | ${metricsData[1].title} | ${metricsData[1].unit}
        ${2}  | ${metricsData[2].value} | ${metricsData[2].title} | ${metricsData[2].unit}
        ${3}  | ${metricsData[3].value} | ${metricsData[3].title} | ${metricsData[3].unit}
      `(
        'renders a single stat component for the $title with value and unit',
        ({ index, value, title, unit }) => {
          const metric = findMetrics().at(index);
          expect(metric.props()).toMatchObject({ value, title, unit: unit ?? '' });
        },
      );

      it('will not display a loading icon', () => {
        expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);
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

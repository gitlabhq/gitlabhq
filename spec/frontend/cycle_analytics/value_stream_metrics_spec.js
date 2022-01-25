import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import metricsData from 'test_fixtures/projects/analytics/value_stream_analytics/summary.json';
import waitForPromises from 'helpers/wait_for_promises';
import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { group } from './mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility');

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

    it('renders hidden GlSingleStat components for each metric', async () => {
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
        index | value                   | title                   | unit                   | animationDecimalPlaces | clickable
        ${0}  | ${metricsData[0].value} | ${metricsData[0].title} | ${metricsData[0].unit} | ${0}                   | ${false}
        ${1}  | ${metricsData[1].value} | ${metricsData[1].title} | ${metricsData[1].unit} | ${0}                   | ${false}
        ${2}  | ${metricsData[2].value} | ${metricsData[2].title} | ${metricsData[2].unit} | ${0}                   | ${false}
        ${3}  | ${metricsData[3].value} | ${metricsData[3].title} | ${metricsData[3].unit} | ${1}                   | ${true}
      `('metric tiles', ({ index, value, title, unit, animationDecimalPlaces, clickable }) => {
        it(`renders a single stat component for "${title}" with value and unit`, () => {
          const metric = findMetrics().at(index);
          expect(metric.props()).toMatchObject({ value, title, unit: unit ?? '' });
          expect(metric.isVisible()).toBe(true);
        });

        it(`${
          clickable ? 'redirects' : "doesn't redirect"
        } when the user clicks the "${title}" metric`, () => {
          const metric = findMetrics().at(index);
          metric.vm.$emit('click');
          if (clickable) {
            expect(redirectTo).toHaveBeenCalledWith(metricsData[index].links[0].url);
          } else {
            expect(redirectTo).not.toHaveBeenCalled();
          }
        });

        it(`will render ${animationDecimalPlaces} decimal places for the ${title} metric with the value "${value}"`, () => {
          const metric = findMetrics().at(index);
          expect(metric.props('animationDecimalPlaces')).toBe(animationDecimalPlaces);
        });
      });

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

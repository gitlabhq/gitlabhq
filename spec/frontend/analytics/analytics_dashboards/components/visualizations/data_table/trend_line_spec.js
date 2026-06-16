import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/src/charts';
import {
  GL_COLOR_DATA_GREEN_400,
  GL_COLOR_DATA_BLUE_600,
} from '@gitlab/ui/src/tokens/build/js/tokens';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TREND_STYLE_DESC, TREND_STYLE_NONE } from '~/analytics/dashboards/constants';
import TrendLine from '~/analytics/analytics_dashboards/components/visualizations/data_table/trend_line.vue';

describe('TrendLine', () => {
  let wrapper;
  const tooltipLabel = 'cool tooltip text';
  const data = [
    ['Jan', 20],
    ['Feb', 5],
    ['Mar', 4],
    ['Apr', 11],
    ['May', 13],
    ['Jun', 21],
  ];

  const findSparkline = () => wrapper.findComponent(GlSparklineChart);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  describe('default', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(TrendLine, {
        propsData: { data, tooltipLabel },
      });
    });

    it('renders the trend sparkline', () => {
      expect(findSparkline().props('data')).toEqual(data);
    });

    it('renders the default color gradient', () => {
      expect(findSparkline().props('gradient')).toEqual([
        GL_COLOR_DATA_GREEN_400,
        GL_COLOR_DATA_BLUE_600,
      ]);
    });

    it('passes the tooltipLabel to the sparkline', () => {
      expect(findSparkline().props('tooltipLabel')).toBe(tooltipLabel);
    });
  });

  describe('no data', () => {
    it('renders a loading state', () => {
      wrapper = shallowMountExtended(TrendLine, {
        propsData: { data: [] },
      });

      expect(findSparkline().exists()).toBe(false);
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('with trendStyle = DESC', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(TrendLine, {
        propsData: { data, trendStyle: TREND_STYLE_DESC },
      });
    });

    it('reverses the default color gradient', () => {
      expect(findSparkline().props('gradient')).toEqual([
        GL_COLOR_DATA_BLUE_600,
        GL_COLOR_DATA_GREEN_400,
      ]);
    });
  });

  describe('with trendStyle = NONE', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(TrendLine, {
        propsData: { data, trendStyle: TREND_STYLE_NONE },
      });
    });

    it('removes the gradient color', () => {
      expect(findSparkline().props('gradient')).toEqual([]);
    });
  });
});

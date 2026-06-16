import { mountExtended } from 'helpers/vue_test_utils_helper';
import { TREND_STYLE_DESC } from '~/analytics/dashboards/constants';
import ChangePercentageIndicator from '~/analytics/analytics_dashboards/components/visualizations/data_table/change_percentage_indicator.vue';

describe('ChangePercentageIndicator', () => {
  let wrapper;

  const findUpTrendIndicator = () => wrapper.findByTestId('trend-up-icon');
  const findDownTrendIndicator = () => wrapper.findByTestId('trend-down-icon');
  const findTrendIndicatorColor = () => wrapper.findComponent('span').classes();
  const findNoChangeTooltip = () => wrapper.findByTestId('metric-cell-no-change');

  describe('default', () => {
    beforeEach(() => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: 0.25 },
      });
    });

    it('renders the % change', () => {
      expect(wrapper.text()).toBe('25.0%');
    });

    it('does not render the "no change" tooltip', () => {
      expect(findNoChangeTooltip().exists()).toBe(false);
    });

    it('renders the up trend indicator as positive', () => {
      expect(findUpTrendIndicator().exists()).toBe(true);
      expect(findTrendIndicatorColor()).toContain('gl-text-success');
    });

    it('renders the down trend indicator as negative', () => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: -0.25 },
      });

      expect(findDownTrendIndicator().exists()).toBe(true);
      expect(findTrendIndicatorColor()).toContain('gl-text-danger');
    });
  });

  describe('no change in trend', () => {
    it('renders the "no change" tooltip', () => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: 0 },
      });

      expect(findNoChangeTooltip().text()).toBe('0.0%');
    });
  });

  describe('invalid trend', () => {
    it('renders the "no change" tooltip', () => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: 'n/a' },
      });

      expect(findNoChangeTooltip().exists()).toBe(true);
      expect(findNoChangeTooltip().text()).toBe('n/a');
    });
  });

  describe('with trendStyle = DESC', () => {
    beforeEach(() => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: 0.25, trendStyle: TREND_STYLE_DESC },
      });
    });

    it('renders the up trend indicator as negative', () => {
      expect(findUpTrendIndicator().exists()).toBe(true);
      expect(findTrendIndicatorColor()).toContain('gl-text-danger');
    });

    it('renders the down trend indicator as positive', () => {
      wrapper = mountExtended(ChangePercentageIndicator, {
        propsData: { value: -0.25, trendStyle: TREND_STYLE_DESC },
      });

      expect(findDownTrendIndicator().exists()).toBe(true);
      expect(findTrendIndicatorColor()).toContain('gl-text-success');
    });
  });
});

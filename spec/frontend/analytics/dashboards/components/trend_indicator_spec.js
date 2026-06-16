import { shallowMount } from '@vue/test-utils';
import { TREND_STYLE_DESC, TREND_STYLE_NONE } from '~/analytics/dashboards/constants';
import TrendIndicator from '~/analytics/dashboards/components/trend_indicator.vue';

describe('Analytics trend indicator', () => {
  let wrapper;

  function createComponent(propsData = {}) {
    wrapper = shallowMount(TrendIndicator, { propsData });
  }

  it('renders a positive change with green text', () => {
    createComponent({ change: 100 });
    expect(wrapper.classes('gl-text-success')).toBe(true);
  });

  it('renders a negative change with red text', () => {
    createComponent({ change: -100 });
    expect(wrapper.classes('gl-text-danger')).toBe(true);
  });

  it('renders a positive change with red text when trendStyle = DESC', () => {
    createComponent({ change: 100, trendStyle: TREND_STYLE_DESC });
    expect(wrapper.classes('gl-text-danger')).toBe(true);
  });

  it('renders a negative change with green text when trendStyle = DESC', () => {
    createComponent({ change: -100, trendStyle: TREND_STYLE_DESC });
    expect(wrapper.classes('gl-text-success')).toBe(true);
  });

  it('renders the change with default color when trendStyle = NONE', () => {
    createComponent({ change: 100, trendStyle: TREND_STYLE_NONE });
    expect(wrapper.classes('gl-text-color-default')).toBe(true);
  });
});

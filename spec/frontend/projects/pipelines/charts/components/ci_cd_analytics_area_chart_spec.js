import { mount } from '@vue/test-utils';
import CiCdAnalyticsAreaChart from '~/vue_shared/components/ci_cd_analytics/ci_cd_analytics_area_chart.vue';
import { transformedAreaChartData } from '../mock_data';

describe('CiCdAnalyticsAreaChart', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(CiCdAnalyticsAreaChart, {
      propsData: {
        chartData: transformedAreaChartData,
        areaChartOptions: {
          xAxis: {
            name: 'X axis title',
            type: 'category',
          },
          yAxis: {
            name: 'Y axis title',
          },
        },
      },
      slots: {
        default: 'Some title',
      },
      stubs: {
        GlAreaChart: true,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});

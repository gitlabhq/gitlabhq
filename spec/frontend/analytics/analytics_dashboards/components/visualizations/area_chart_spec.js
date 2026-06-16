import { GlAreaChart } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AreaChart from '~/analytics/analytics_dashboards/components/visualizations/area_chart.vue';
import { stubComponent } from 'helpers/stub_component';
import { CHART_TOOLTIP_TITLE_FORMATTERS, UNITS } from '~/analytics/shared/constants';

describe('AreaChart Visualization', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const mockData = [{ name: 'Production', data: ['Dec 2025', 2000] }];
  const mockOptions = {
    yAxis: { name: 'Deploys' },
    xAxis: { name: 'Month' },
  };

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findChartTooltipTitle = () => wrapper.findByTestId('chart-tooltip-title');
  const findChartTooltipValue = () => wrapper.findByTestId('chart-tooltip-value');

  const createWrapper = ({ data = mockData, options = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(AreaChart, {
      propsData: {
        data,
        options: { ...mockOptions, ...options },
      },
      stubs,
    });
  };

  it('should render area chart with the provided data and default options', () => {
    createWrapper({});

    expect(findAreaChart().props()).toMatchObject({
      data: expect.arrayContaining([
        {
          name: 'Production',
          data: ['Dec 2025', 2000],
          type: 'line',
          areaStyle: {
            opacity: 0.2,
          },
        },
      ]),
      option: expect.objectContaining({
        yAxis: { name: 'Deploys', type: 'value' },
        xAxis: { name: 'Month', type: 'category' },
      }),
      includeLegendAvgMax: true,
    });
    expect(findAreaChart().attributes('responsive')).toBe('');
  });

  it('can toggle legend average/max values', () => {
    createWrapper({ options: { includeLegendAvgMax: false } });

    expect(findAreaChart().props().includeLegendAvgMax).toBe(false);
  });

  it('does not pass `tooltip` option to chart options', () => {
    createWrapper({ options: { tooltip: { description: 'Panel tooltip' } } });

    expect(findAreaChart().props().option).not.toHaveProperty('tooltip');
  });

  describe('tooltip', () => {
    const mockSeries = {
      name: 'Dec 2025',
      seriesName: 'Production',
      seriesIndex: 0,
      value: ['Dec 2025', 2000],
    };

    const createTooltipStub = (seriesData = [mockSeries]) => ({
      GlAreaChart: stubComponent(GlAreaChart, {
        data() {
          const [title, value] = seriesData[0].value;
          return { title: `${title} (xAxisTitle)`, value, params: { seriesData } };
        },
        template: `
          <div>
            <slot name="tooltip-title" :title="title" :params="params"></slot>
            <slot name="tooltip-value" :value="value"></slot>
          </div>
        `,
      }),
    });

    it('formats the tooltip correctly when no options have been defined', () => {
      createWrapper({
        options: {
          chartTooltip: undefined,
        },
        stubs: createTooltipStub(),
      });

      expect(findChartTooltipTitle().text()).toBe('Dec 2025 (xAxisTitle)');
      expect(findChartTooltipValue().text()).toBe('2000');
    });

    it('formats the tooltip correctly when options have been defined', () => {
      createWrapper({
        options: {
          chartTooltip: {
            titleFormatter: CHART_TOOLTIP_TITLE_FORMATTERS.VALUE_ONLY,
            valueUnit: UNITS.COUNT,
          },
        },
        stubs: createTooltipStub(),
      });

      expect(findChartTooltipTitle().text()).toBe('Dec 2025');
      expect(findChartTooltipValue().text()).toBe('2,000');
    });
  });
});

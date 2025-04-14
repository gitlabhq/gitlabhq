import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import PipelineDurationChart from '~/projects/pipelines/charts/components/pipeline_duration_chart.vue';
import { stubComponent } from 'helpers/stub_component';

describe('PipelineDurationChart', () => {
  let wrapper;

  const findLineChart = () => wrapper.findComponent(GlLineChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(PipelineDurationChart, {
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays loading state', () => {
    createComponent({ props: { loading: true } });

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('displays chart', () => {
    createComponent();

    expect(findLineChart().props()).toMatchObject({
      includeLegendAvgMax: false,
      option: {
        yAxis: {
          name: 'Minutes',
          type: 'value',
        },
        xAxis: {
          name: 'Time',
          type: 'category',
        },
      },
      data: [
        { data: [], name: 'Median (50th percentile)' },
        { data: [], name: '95th percentile' },
      ],
    });
  });

  it('formats seconds in y axis labels as minutes', () => {
    const { formatter } = findLineChart().props('option').yAxis.axisLabel;

    expect(formatter(0)).toBe('0');
    expect(formatter(1)).toBe('0.02');
    expect(formatter(60)).toBe('1');
    expect(formatter(3600)).toBe('60');
    expect(formatter(60 * 10 ** 3)).toBe('1k');
    expect(formatter(3600 * 10 ** 4)).toBe('600k');
  });

  it('displays chart with data', () => {
    createComponent({
      props: {
        timeSeries: [
          { label: '2021-12-01', durationStatistics: { p50: 100, p95: 110 } },
          { label: '2021-12-02', durationStatistics: { p50: 101, p95: 111 } },
        ],
      },
    });

    expect(findLineChart().props('data')).toEqual([
      {
        data: [
          ['2021-12-01', 100],
          ['2021-12-02', 101],
        ],
        name: 'Median (50th percentile)',
      },
      {
        data: [
          ['2021-12-01', 110],
          ['2021-12-02', 111],
        ],
        name: '95th percentile',
      },
    ]);
  });

  describe('formats tooltip', () => {
    const oneMinute = 60;
    const oneHour = 3600;
    const oneDay = oneHour * 24;

    it.each`
      date            | value                           | expectedTooltip
      ${'2021-12-01'} | ${oneMinute}                    | ${'Dec 1, 2021 - 1m'}
      ${'2022-12-15'} | ${oneHour + oneMinute}          | ${'Dec 15, 2022 - 1h 1m'}
      ${'2023-12-31'} | ${oneDay + oneHour + oneMinute} | ${'Dec 31, 2023 - 1d 1h 1m'}
    `('$expectedTooltip', ({ date, value, expectedTooltip }) => {
      createComponent({
        stubs: {
          GlLineChart: stubComponent(GlLineChart, {
            template: `<div>
                        <slot name="tooltip-title" :params="{ value: '${date}' }"></slot>
                        -
                        <slot name="tooltip-value" :value="${value}"></slot>
                      </div>`,
          }),
        },
      });

      expect(findLineChart().text()).toMatchInterpolatedText(expectedTooltip);
    });
  });
});

import { GlLoadingIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import PipelineDurationChart from '~/projects/pipelines/charts/components/pipeline_duration_chart.vue';

describe('PipelineDurationChart', () => {
  let wrapper;

  const findLineChart = () => wrapper.findComponent(GlLineChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(PipelineDurationChart, {
      propsData: {
        ...props,
      },
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
          name: 'Seconds',
        },
        xAxis: {
          name: 'Time',
          type: 'category',
        },
      },
      data: [
        { data: [], name: 'Mean (50th percentile)' },
        { data: [], name: '95th percentile' },
      ],
    });
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
        name: 'Mean (50th percentile)',
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
});

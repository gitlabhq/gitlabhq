import { GlLoadingIcon } from '@gitlab/ui';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import PipelineStatusChart from '~/projects/pipelines/charts/components/pipeline_status_chart.vue';
import { stubComponent } from 'helpers/stub_component';

describe('PipelineStatusChart', () => {
  let wrapper;

  const findStackedColumnChart = () => wrapper.findComponent(GlStackedColumnChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(PipelineStatusChart, {
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

    expect(findStackedColumnChart().props()).toMatchObject({
      bars: [
        { data: [], name: 'Successful' },
        { data: [], name: 'Failed' },
        { data: [], name: 'Other (Cancelled, Skipped)' },
      ],
      groupBy: [],
      customPalette: ['#619025', '#b93d71', '#617ae2'],
      xAxisTitle: 'Time',
      xAxisType: 'category',
      yAxisTitle: 'Number of Pipelines',
      includeLegendAvgMax: false,
    });
  });

  it('displays chart with data', () => {
    createComponent({
      props: {
        timeSeries: [
          { label: '2021-12-01', successCount: 10, failedCount: 20, otherCount: 30 },
          { label: '2021-12-02', successCount: 11, failedCount: 21, otherCount: 31 },
        ],
      },
    });

    expect(findStackedColumnChart().props('groupBy')).toEqual(['2021-12-01', '2021-12-02']);
    expect(findStackedColumnChart().props('bars')).toEqual([
      { data: [10, 11], name: 'Successful' },
      { data: [20, 21], name: 'Failed' },
      { data: [30, 31], name: 'Other (Cancelled, Skipped)' },
    ]);
  });

  describe('formats tooltip', () => {
    it.each`
      date            | expectedTooltip
      ${'2021-12-01'} | ${'Dec 1, 2021'}
      ${'2022-12-15'} | ${'Dec 15, 2022'}
      ${'2023-12-31'} | ${'Dec 31, 2023'}
    `('$expectedTooltip', ({ date, expectedTooltip }) => {
      createComponent({
        stubs: {
          GlStackedColumnChart: stubComponent(GlStackedColumnChart, {
            template: `<div>
                        <slot name="tooltip-title" :params="{ value: '${date}' }"></slot>
                      </div>`,
          }),
        },
      });

      expect(findStackedColumnChart().text()).toMatchInterpolatedText(expectedTooltip);
    });
  });
});

import { GlChart } from '@gitlab/ui/dist/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimelineChart from '~/error_tracking/components/timeline_chart.vue';

const MOCK_HEIGHT = 123;

describe('TimelineChart', () => {
  let wrapper;

  function mountComponent(timelineData = []) {
    wrapper = shallowMountExtended(TimelineChart, {
      stubs: { GlChart: true },
      propsData: {
        timelineData: [...timelineData],
        height: MOCK_HEIGHT,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('does not render a chart if timelineData is missing', () => {
    wrapper = shallowMountExtended(TimelineChart, {
      stubs: { GlChart: true },
      propsData: {
        timelineData: undefined,
        height: MOCK_HEIGHT,
      },
    });
    expect(wrapper.findComponent(GlChart).exists()).toBe(false);
  });

  it('renders a gl-chart', () => {
    expect(wrapper.findComponent(GlChart).exists()).toBe(true);
    expect(wrapper.findComponent(GlChart).props('height')).toBe(MOCK_HEIGHT);
  });

  describe('timeline-data', () => {
    describe.each([
      {
        mockItems: [
          [1686218400, 1],
          [1686222000, 2],
        ],
        expectedX: ['June 8, 2023 at 10:00:00 AM GMT', 'June 8, 2023 at 11:00:00 AM GMT'],
        expectedY: [1, 2],
        description: 'tuples with dates as timestamps in seconds',
      },
      {
        mockItems: [
          ['06-05-2023', 1],
          ['06-06-2023', 2],
        ],
        expectedX: ['June 5, 2023 at 12:00:00 AM GMT', 'June 6, 2023 at 12:00:00 AM GMT'],
        expectedY: [1, 2],
        description: 'tuples with non-numeric dates',
      },
      {
        mockItems: [
          { time: 1686218400, count: 1 },
          { time: 1686222000, count: 2 },
        ],
        expectedX: ['June 8, 2023 at 10:00:00 AM GMT', 'June 8, 2023 at 11:00:00 AM GMT'],
        expectedY: [1, 2],
        description: 'objects with dates as timestamps in seconds',
      },
      {
        mockItems: [
          { time: '06-05-2023', count: 1 },
          { time: '06-06-2023', count: 2 },
        ],
        expectedX: ['June 5, 2023 at 12:00:00 AM GMT', 'June 6, 2023 at 12:00:00 AM GMT'],
        expectedY: [1, 2],
        description: 'objects with non-numeric dates',
      },
    ])('when timeline-data items are $description', ({ mockItems, expectedX, expectedY }) => {
      it(`renders the chart correctly`, () => {
        mountComponent(mockItems);

        const chartOptions = wrapper.findComponent(GlChart).props('options');
        const xData = chartOptions.xAxis.data;
        const yData = chartOptions.series[0].data;
        expect(xData).toEqual(expectedX);
        expect(yData).toEqual(expectedY);
      });
    });
  });
});

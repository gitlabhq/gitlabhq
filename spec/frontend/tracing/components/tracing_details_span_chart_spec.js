import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDetailsSpansChart from '~/tracing/components/tracing_details_spans_chart.vue';

describe('TracingDetailsSpansChart', () => {
  const mockSpans = [
    {
      operation: 'operation-1',
      service: 'service-1',
      startTimeMs: 100,
      durationMs: 150,
      children: [
        {
          operation: 'operation-3',
          service: 'service-3',
          startTimeMs: 0,
          durationMs: 100,
          children: [],
        },
      ],
    },
    {
      operation: 'operation-2',
      service: 'service-2',
      startTimeMs: 100,
      durationMs: 200,
      children: [],
    },
  ];

  const mockProps = {
    spans: mockSpans,
    traceDurationMs: 300,
    serviceToColor: {
      'service-1': 'blue-500',
      'service-2': 'orange-500',
    },
  };

  let wrapper;

  const getSpan = (index, depth = 0) => wrapper.findByTestId(`span-container-${depth}-${index}`);
  const getSpanDetails = (index, depth = 0) =>
    getSpan(index, depth).find('[data-testid="span-details"]');

  const getToggleButton = (index, depth = 0) =>
    getSpanDetails(index, depth).findComponent(GlButton);

  const getSpanDuration = (index, depth = 0) =>
    getSpan(index, depth).find('[data-testid="span-duration"]');

  const getSpanDurationBar = (index, depth = 0) =>
    getSpanDuration(index, depth).find('[data-testid="span-duration-bar"]');

  beforeEach(() => {
    wrapper = shallowMountExtended(TracingDetailsSpansChart, {
      propsData: {
        ...mockProps,
      },
    });
  });

  it('renders the correct number of spans', () => {
    expect(wrapper.findAll('[data-testid^="span-container-"]')).toHaveLength(
      mockProps.spans.length,
    );
  });

  it('renders tracing-details-spans-chart only if span has children', () => {
    const childrenChart = getSpan(0).findComponent(TracingDetailsSpansChart);

    expect(childrenChart.exists()).toBe(true);
    expect(childrenChart.props('depth')).toBe(1);
    expect(childrenChart.props('traceDurationMs')).toBe(mockProps.traceDurationMs);
    expect(childrenChart.props('serviceToColor')).toBe(mockProps.serviceToColor);
    expect(childrenChart.props('spans')).toBe(mockProps.spans[0].children);

    // span with no children
    expect(getSpan(1).findComponent(TracingDetailsSpansChart).exists()).toBe(false);
  });

  it('toggle the children spans when clicking the expand button', async () => {
    await getToggleButton(0).vm.$emit('click');

    expect(getToggleButton(0).props('icon')).toBe('chevron-up');
    expect(getSpan(0).findComponent(TracingDetailsSpansChart).exists()).toBe(false);

    await getToggleButton(0).vm.$emit('click');

    expect(getToggleButton(0).props('icon')).toBe('chevron-down');
    expect(getSpan(0).findComponent(TracingDetailsSpansChart).exists()).toBe(true);
  });

  it('reset the expanded state when the spans change', async () => {
    await getToggleButton(0).vm.$emit('click');
    expect(getSpan(0).findComponent(TracingDetailsSpansChart).exists()).toBe(false);

    await wrapper.setProps({ spans: [...mockSpans] });
    expect(getSpan(0).findComponent(TracingDetailsSpansChart).exists()).toBe(true);
  });

  describe('span details', () => {
    it('renders the spans details with left padding based on depth', () => {
      wrapper = shallowMountExtended(TracingDetailsSpansChart, {
        propsData: {
          ...mockProps,
          depth: 2,
        },
      });
      expect(getSpanDetails(0, 2).element.style.paddingLeft).toBe('32px');
    });

    it('renders span operation and service name', () => {
      expect(getSpanDetails(0).text()).toBe('operation-1 service-1');
    });

    it('renders the expanded button', () => {
      expect(getToggleButton(0).props('icon')).toBe('chevron-down');
    });
  });

  describe('span duration', () => {
    it('renders the duration value', () => {
      expect(
        wrapper.findByTestId('span-container-0-0').find('[data-testid="span-duration"]').text(),
      ).toBe('150 ms');
    });

    it('renders the proper color based on service', () => {
      expect(
        wrapper
          .findByTestId('span-container-0-0')
          .find('[data-testid="span-duration-bar"]')
          .classes(),
      ).toContain('gl-bg-data-viz-blue-500');
    });

    it('renders the bar with the proper style', () => {
      expect(getSpanDuration(0).element.style.marginLeft).toBe('33%');
      expect(
        getSpanDurationBar(0).find('[data-testid="span-duration-bar"]').element.style.width,
      ).toBe('50%');
    });

    it('bar width should not be less than 0.5% and not bigger than 100%', () => {
      wrapper = shallowMountExtended(TracingDetailsSpansChart, {
        propsData: {
          serviceToColor: {
            'service-1': 'blue-500',
            'service-2': 'orange-500',
          },
          traceDurationMs: 300,
          spans: [
            {
              operation: 'operation-1',
              service: 'service-1',
              startTimeMs: 0,
              durationMs: 1,
              children: [],
            },
            {
              operation: 'operation-2',
              service: 'service-2',
              startTimeMs: 0,
              durationMs: 310,
              children: [],
            },
          ],
        },
      });
      expect(
        getSpanDurationBar(0).find('[data-testid="span-duration-bar"]').element.style.width,
      ).toBe('0.5%');
      expect(
        getSpanDurationBar(1).find('[data-testid="span-duration-bar"]').element.style.width,
      ).toBe('100%');
    });
  });
});

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDetailsChart from '~/tracing/components/tracing_details_chart.vue';
import TracingDetailsSpansChart from '~/tracing/components/tracing_details_spans_chart.vue';
import {
  mapTraceToTreeRoot,
  assignColorToServices,
  durationNanoToMs,
} from '~/tracing/components/trace_utils';

jest.mock('~/tracing/components/trace_utils');

describe('TracingDetailsChart', () => {
  let wrapper;

  const mockTrace = {
    timestamp: '2023-08-07T15:03:32.199806Z',
    trace_id: 'dabb7ae1-2501-8e57-18e1-30ab21a9ab19',
    service_name: 'tracegen',
    operation: 'lets-go',
    statusCode: 'STATUS_CODE_UNSET',
    duration_nano: 100120000,
    spans: [
      {
        timestamp: '2023-08-07T15:03:32.199806Z',
        span_id: 'A1FB81EB031B09E8',
        trace_id: 'dabb7ae1-2501-8e57-18e1-30ab21a9ab19',
        service_name: 'tracegen',
        operation: 'lets-go',
        duration_nano: 100120000,
        parent_span_id: '',
        statusCode: 'STATUS_CODE_UNSET',
      },
    ],
  };

  beforeEach(() => {
    mapTraceToTreeRoot.mockReturnValue(mockTrace.spans[0]);
    assignColorToServices.mockReturnValue({ tracegen: 'red' });
    durationNanoToMs.mockReturnValue(100);

    wrapper = shallowMountExtended(TracingDetailsChart, {
      propsData: {
        trace: mockTrace,
      },
    });
  });

  it('renders the TracingDetailsSpansChart component', () => {
    expect(wrapper.findComponent(TracingDetailsSpansChart).exists()).toBe(true);
  });

  it('passes the correct props to the TracingDetailsSpansChart component', () => {
    const tracingDetailsSpansChart = wrapper.findComponent(TracingDetailsSpansChart);

    expect(mapTraceToTreeRoot).toHaveBeenCalledWith(mockTrace);

    expect(tracingDetailsSpansChart.props('spans')).toEqual([mockTrace.spans[0]]);
    expect(tracingDetailsSpansChart.props('traceDurationMs')).toBe(100);
    expect(tracingDetailsSpansChart.props('serviceToColor')).toEqual({ tracegen: 'red' });
  });
});

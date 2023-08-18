import _ from 'lodash';
import {
  mapTraceToTreeRoot,
  durationNanoToMs,
  formatDurationMs,
  formatTraceDuration,
  assignColorToServices,
} from '~/tracing/components/trace_utils';

describe('trace_utils', () => {
  describe('durationNanoToMs', () => {
    it('converts a duration value from nano to ms', () => {
      expect(durationNanoToMs(1000000001)).toBe(1000000);
    });
  });

  describe('formatDurationMs', () => {
    it('formats a duration ms value', () => {
      expect(formatDurationMs(1000)).toBe('1000 ms');
    });
  });

  describe('formatTraceDuration', () => {
    it('formats the trace duration nano value', () => {
      expect(formatTraceDuration(1000000001)).toBe('1000000 ms');
    });
  });

  describe('assignColorToService', () => {
    it('should assign the right palette', () => {
      const trace = { duration_nane: 100000, spans: [] };
      trace.spans = _.times(31).map((i) => ({
        timestamp: '2023-08-07T15:03:32.199806Z',
        span_id: `SPAN-${i}`,
        trace_id: 'TRACE-1',
        service_name: `service-${i}`,
        operation: 'op',
        duration_nano: 100000,
        parent_span_id: '',
      }));

      expect(assignColorToServices(trace)).toEqual({
        'service-0': 'blue-500',
        'service-1': 'orange-500',
        'service-2': 'aqua-500',
        'service-3': 'green-500',
        'service-4': 'magenta-500',
        'service-5': 'blue-600',
        'service-6': 'orange-600',
        'service-7': 'aqua-600',
        'service-8': 'green-600',
        'service-9': 'magenta-600',
        'service-10': 'blue-700',
        'service-11': 'orange-700',
        'service-12': 'aqua-700',
        'service-13': 'green-700',
        'service-14': 'magenta-700',
        'service-15': 'blue-800',
        'service-16': 'orange-800',
        'service-17': 'aqua-800',
        'service-18': 'green-800',
        'service-19': 'magenta-800',
        'service-20': 'blue-900',
        'service-21': 'orange-900',
        'service-22': 'aqua-900',
        'service-23': 'green-900',
        'service-24': 'magenta-900',
        'service-25': 'blue-950',
        'service-26': 'orange-950',
        'service-27': 'aqua-950',
        'service-28': 'green-950',
        'service-29': 'magenta-950',
        // restart pallete
        'service-30': 'blue-500',
      });
    });
  });

  describe('mapTraceToTreeRoot', () => {
    it('should map a trace data to tree data and return the root node', () => {
      const trace = {
        spans: [
          {
            timestamp: '2023-08-07T15:03:32.199806Z',
            span_id: 'SPAN-1',
            trace_id: 'TRACE-1',
            service_name: 'tracegen',
            operation: 'lets-go',
            duration_nano: 100120000,
            parent_span_id: '',
          },
          {
            timestamp: '2023-08-07T15:03:32.199871Z',
            span_id: 'SPAN-2',
            trace_id: 'TRACE-1',
            service_name: 'tracegen',
            operation: 'okey-dokey',
            duration_nano: 100055000,
            parent_span_id: 'SPAN-1',
          },
          {
            timestamp: '2023-08-07T15:03:53.199871Z',
            span_id: 'SPAN-3',
            trace_id: 'TRACE-1',
            service_name: 'tracegen',
            operation: 'okey-dokey',
            duration_nano: 50027500,
            parent_span_id: 'SPAN-2',
          },
          {
            timestamp: '2023-08-07T15:03:53.199871Z',
            span_id: 'SPAN-4',
            trace_id: 'TRACE-1',
            service_name: 'fake-service-2',
            operation: 'okey-dokey',
            duration_nano: 50027500,
            parent_span_id: 'SPAN-2',
          },
        ],
        duration_nano: 3000000,
      };

      expect(mapTraceToTreeRoot(trace)).toEqual({
        durationMs: 100120,
        operation: 'lets-go',
        service: 'tracegen',
        spanId: 'SPAN-1',
        startTimeMs: 0,
        timestamp: '2023-08-07T15:03:32.199806Z',
        children: [
          {
            durationMs: 100055,
            operation: 'okey-dokey',
            service: 'tracegen',
            spanId: 'SPAN-2',
            startTimeMs: 0,
            timestamp: '2023-08-07T15:03:32.199871Z',
            children: [
              {
                children: [],
                durationMs: 50028,
                operation: 'okey-dokey',
                service: 'tracegen',
                spanId: 'SPAN-3',
                startTimeMs: 21000,
                timestamp: '2023-08-07T15:03:53.199871Z',
              },
              {
                children: [],
                durationMs: 50028,
                operation: 'okey-dokey',
                service: 'fake-service-2',
                spanId: 'SPAN-4',
                startTimeMs: 21000,
                timestamp: '2023-08-07T15:03:53.199871Z',
              },
            ],
          },
        ],
      });
    });
  });
});

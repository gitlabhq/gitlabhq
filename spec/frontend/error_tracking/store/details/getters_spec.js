import * as getters from '~/error_tracking/store/details/getters';

describe('Sentry error details store getters', () => {
  describe('stacktrace', () => {
    it('should return empty stacktrace when there are no entries', () => {
      const state = {
        stacktraceData: { stack_trace_entries: null },
      };
      expect(getters.stacktrace(state)).toEqual([]);
    });

    it('should get stacktrace', () => {
      const state = {
        stacktraceData: { stack_trace_entries: [1, 2] },
      };
      expect(getters.stacktrace(state)).toEqual([2, 1]);
    });
  });
});

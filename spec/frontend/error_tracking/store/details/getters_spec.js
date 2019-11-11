import * as getters from '~/error_tracking/store/details/getters';

describe('Sentry error details store getters', () => {
  const state = {
    stacktraceData: { stack_trace_entries: [1, 2] },
  };

  describe('stacktrace', () => {
    it('should get stacktrace', () => {
      expect(getters.stacktrace(state)).toEqual([2, 1]);
    });
  });
});

// eslint-disable-next-line import/prefer-default-export
export const stacktrace = state =>
  state.stacktraceData.stack_trace_entries
    ? state.stacktraceData.stack_trace_entries.reverse()
    : [];

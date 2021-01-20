export const stacktrace = (state) =>
  state.stacktraceData.stack_trace_entries
    ? state.stacktraceData.stack_trace_entries.reverse()
    : [];

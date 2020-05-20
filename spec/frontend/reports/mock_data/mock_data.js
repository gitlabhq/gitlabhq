export const issue = {
  result: 'failure',
  name: 'Test#sum when a is 1 and b is 2 returns summary',
  execution_time: 0.009411,
  system_output:
    "Failure/Error: is_expected.to eq(3)\n\n  expected: 3\n       got: -1\n\n  (compared using ==)\n./spec/test_spec.rb:12:in `block (4 levels) in \u003ctop (required)\u003e'",
};

export const failedReport = {
  summary: { total: 11, resolved: 0, errored: 2, failed: 0 },
  suites: [
    {
      name: 'rspec:pg',
      status: 'error',
      summary: { total: 0, resolved: 0, errored: 0, failed: 0 },
      new_failures: [],
      resolved_failures: [],
      existing_failures: [],
      new_errors: [],
      resolved_errors: [],
      existing_errors: [],
    },
  ],
};

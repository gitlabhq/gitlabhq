import { formatTime } from '~/lib/utils/datetime_utility';
import { TestStatus } from '~/pipelines/constants';

export const testCases = [
  {
    classname: 'spec.test_spec',
    execution_time: 0.000748,
    name: 'Test#subtract when a is 1 and b is 2 raises an error',
    stack_trace: null,
    status: TestStatus.SUCCESS,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    execution_time: 0.000064,
    name: 'Test#subtract when a is 2 and b is 1 returns correct result',
    stack_trace: null,
    status: TestStatus.SUCCESS,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    execution_time: 0.009292,
    name: 'Test#sum when a is 1 and b is 2 returns summary',
    stack_trace: null,
    status: TestStatus.FAILED,
    system_output:
      "Failure/Error: is_expected.to eq(3)\n\n  expected: 3\n       got: -1\n\n  (compared using ==)\n./spec/test_spec.rb:12:in `block (4 levels) in <top (required)>'",
  },
  {
    classname: 'spec.test_spec',
    execution_time: 0.00018,
    name: 'Test#sum when a is 100 and b is 200 returns summary',
    stack_trace: null,
    status: TestStatus.FAILED,
    system_output:
      "Failure/Error: is_expected.to eq(300)\n\n  expected: 300\n       got: -100\n\n  (compared using ==)\n./spec/test_spec.rb:21:in `block (4 levels) in <top (required)>'",
  },
  {
    classname: 'spec.test_spec',
    execution_time: 0,
    name: 'Test#skipped text',
    stack_trace: null,
    status: TestStatus.SKIPPED,
    system_output: null,
  },
];

export const testCasesFormatted = [
  {
    ...testCases[2],
    icon: 'status_failed_borderless',
    formattedTime: formatTime(testCases[0].execution_time * 1000),
  },
  {
    ...testCases[3],
    icon: 'status_failed_borderless',
    formattedTime: formatTime(testCases[1].execution_time * 1000),
  },
  {
    ...testCases[4],
    icon: 'status_skipped_borderless',
    formattedTime: formatTime(testCases[2].execution_time * 1000),
  },
  {
    ...testCases[0],
    icon: 'status_success_borderless',
    formattedTime: formatTime(testCases[3].execution_time * 1000),
  },
  {
    ...testCases[1],
    icon: 'status_success_borderless',
    formattedTime: formatTime(testCases[4].execution_time * 1000),
  },
];

export const testSuites = [
  {
    error_count: 0,
    failed_count: 2,
    name: 'rspec:osx',
    skipped_count: 0,
    success_count: 2,
    test_cases: testCases,
    total_count: 4,
    total_time: 60,
  },
  {
    error_count: 0,
    failed_count: 10,
    name: 'rspec:osx',
    skipped_count: 0,
    success_count: 50,
    test_cases: [],
    total_count: 60,
    total_time: 0.010284,
  },
];

export const testSuitesFormatted = testSuites.map(x => ({
  ...x,
  formattedTime: formatTime(x.total_time * 1000),
}));

export const testReports = {
  error_count: 0,
  failed_count: 2,
  skipped_count: 0,
  success_count: 2,
  test_suites: testSuites,
  total_count: 4,
  total_time: 0.010284,
};

export const testReportsWithNoSuites = {
  error_count: 0,
  failed_count: 2,
  skipped_count: 0,
  success_count: 2,
  test_suites: [],
  total_count: 4,
  total_time: 0.010284,
};

import { TestStatus } from '~/pipelines/constants';

export default [
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#skipped text',
    stack_trace: null,
    status: TestStatus.SKIPPED,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#error text',
    stack_trace: null,
    status: TestStatus.ERROR,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#unknown text',
    stack_trace: null,
    status: TestStatus.UNKNOWN,
    system_output: null,
  },
];

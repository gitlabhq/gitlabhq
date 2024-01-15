import { testStatus } from '~/ci/pipeline_details/constants';

export default [
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#skipped text',
    stack_trace: null,
    status: testStatus.SKIPPED,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#error text',
    stack_trace: null,
    status: testStatus.ERROR,
    system_output: null,
  },
  {
    classname: 'spec.test_spec',
    file: 'spec/trace_spec.rb',
    execution_time: 0,
    name: 'Test#unknown text',
    stack_trace: null,
    status: testStatus.UNKNOWN,
    system_output: null,
  },
];

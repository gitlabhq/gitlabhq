import {
  normalizeMetric,
  uniqMetricsId,
  parseEnvironmentsResponse,
  removeLeadingSlash,
} from '~/monitoring/stores/utils';

const projectPath = 'gitlab-org/gitlab-test';

describe('normalizeMetric', () => {
  [
    { args: [], expected: 'undefined_undefined' },
    { args: [undefined], expected: 'undefined_undefined' },
    { args: [{ id: 'something' }], expected: 'undefined_something' },
    { args: [{ id: 45 }], expected: 'undefined_45' },
    { args: [{ metric_id: 5 }], expected: '5_undefined' },
    { args: [{ metric_id: 'something' }], expected: 'something_undefined' },
    {
      args: [{ metric_id: 5, id: 'system_metrics_kubernetes_container_memory_total' }],
      expected: '5_system_metrics_kubernetes_container_memory_total',
    },
  ].forEach(({ args, expected }) => {
    it(`normalizes metric to "${expected}" with args=${JSON.stringify(args)}`, () => {
      expect(normalizeMetric(...args)).toEqual({ metric_id: expected, metricId: expected });
    });
  });
});

describe('uniqMetricsId', () => {
  [
    { input: { id: 1 }, expected: 'undefined_1' },
    { input: { metric_id: 2 }, expected: '2_undefined' },
    { input: { metric_id: 2, id: 21 }, expected: '2_21' },
    { input: { metric_id: 22, id: 1 }, expected: '22_1' },
    { input: { metric_id: 'aaa', id: '_a' }, expected: 'aaa__a' },
  ].forEach(({ input, expected }) => {
    it(`creates unique metric ID with ${JSON.stringify(input)}`, () => {
      expect(uniqMetricsId(input)).toEqual(expected);
    });
  });
});

describe('parseEnvironmentsResponse', () => {
  [
    {
      input: null,
      output: [],
    },
    {
      input: undefined,
      output: [],
    },
    {
      input: [],
      output: [],
    },
    {
      input: [
        {
          id: '1',
          name: 'env-1',
        },
      ],
      output: [
        {
          id: 1,
          name: 'env-1',
          metrics_path: `${projectPath}/environments/1/metrics`,
        },
      ],
    },
    {
      input: [
        {
          id: 'gid://gitlab/Environment/12',
          name: 'env-12',
        },
      ],
      output: [
        {
          id: 12,
          name: 'env-12',
          metrics_path: `${projectPath}/environments/12/metrics`,
        },
      ],
    },
  ].forEach(({ input, output }) => {
    it(`parseEnvironmentsResponse returns ${JSON.stringify(output)} with input ${JSON.stringify(
      input,
    )}`, () => {
      expect(parseEnvironmentsResponse(input, projectPath)).toEqual(output);
    });
  });
});

describe('removeLeadingSlash', () => {
  [
    { input: null, output: '' },
    { input: '', output: '' },
    { input: 'gitlab-org', output: 'gitlab-org' },
    { input: 'gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
    { input: '/gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
    { input: '////gitlab-org/gitlab', output: 'gitlab-org/gitlab' },
  ].forEach(({ input, output }) => {
    it(`removeLeadingSlash returns ${output} with input ${input}`, () => {
      expect(removeLeadingSlash(input)).toEqual(output);
    });
  });
});

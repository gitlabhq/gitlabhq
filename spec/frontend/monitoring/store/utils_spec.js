import { normalizeMetric, uniqMetricsId } from '~/monitoring/stores/utils';

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

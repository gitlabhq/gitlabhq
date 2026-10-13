import {
  hiddenMetricsError,
  visibleFieldsOf,
} from '~/glql/components/presenters/utils/hidden_metrics';

const dimension = { key: 'language', label: 'Language', type: 'dimension' };
const median = {
  key: 'Median',
  field: 'timeToMergeQuantile',
  label: 'Median',
  type: 'metric',
  parameters: { quantile: 0.5 },
};
const p75 = { ...median, key: 'p75', label: 'p75', parameters: { quantile: 0.75 } };
const throughputCount = { key: 'throughputCount', label: 'Merged', type: 'metric' };
const fields = [dimension, median, p75, throughputCount];

describe('visibleFieldsOf', () => {
  it.each([undefined, null, 'throughputCount'])(
    'returns every field when hiddenMetrics is %p',
    (hiddenMetrics) => {
      expect(visibleFieldsOf(fields, hiddenMetrics)).toBe(fields);
    },
  );

  it('drops a metric named by its alias', () => {
    expect(visibleFieldsOf(fields, ['throughputCount', 'p75'])).toEqual([dimension, median]);
  });

  it('drops every metric that shares a base key', () => {
    expect(visibleFieldsOf(fields, ['timeToMergeQuantile'])).toEqual([dimension, throughputCount]);
  });

  it('keeps a dimension even when hiddenMetrics names it', () => {
    expect(visibleFieldsOf(fields, ['language'])).toEqual(fields);
  });
});

describe('hiddenMetricsError', () => {
  it.each`
    hiddenMetrics
    ${undefined}
    ${null}
    ${[]}
    ${['throughputCount']}
    ${['timeToMergeQuantile']}
  `('returns null for $hiddenMetrics', ({ hiddenMetrics }) => {
    expect(hiddenMetricsError(hiddenMetrics, fields)).toBeNull();
  });

  it.each(['throughputCount', { throughputCount: true }, 1])(
    'rejects %p because it is not a list',
    (hiddenMetrics) => {
      expect(hiddenMetricsError(hiddenMetrics, fields)).toBe(
        '`hiddenMetrics` must be a list of metric names.',
      );
    },
  );

  it.each`
    hiddenMetrics                 | unknown
    ${['usersCount']}             | ${'usersCount'}
    ${['throughputCount', 'p95']} | ${'p95'}
    ${['language']}               | ${'language'}
  `('names $unknown as an unknown metric', ({ hiddenMetrics, unknown }) => {
    expect(hiddenMetricsError(hiddenMetrics, fields)).toBe(
      `Unknown metric for \`hiddenMetrics\`: \`${unknown}\`.`,
    );
  });
});

import { dimensionMetricValidationError } from '~/glql/utils/chart_validation';

const DIM_A = { key: 'a', label: 'A', name: 'a', type: 'dimension' };
const DIM_B = { key: 'b', label: 'B', name: 'b', type: 'dimension' };
const DIM_C = { key: 'c', label: 'C', name: 'c', type: 'dimension' };
const METRIC_X = { key: 'x', label: 'X', name: 'x', type: 'metric' };
const METRIC_Y = { key: 'y', label: 'Y', name: 'y', type: 'metric' };

describe('dimensionMetricValidationError', () => {
  it('requires at least one dimension', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'barChart',
        dimensions: [],
        metrics: [METRIC_X],
      }),
    ).toBe('barChart requires at least one dimension');
  });

  it('caps dimensions at the default maximum of 2', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'columnChart',
        dimensions: [DIM_A, DIM_B, DIM_C],
        metrics: [METRIC_X],
      }),
    ).toBe('columnChart supports a maximum of 2 dimensions');
  });

  it('caps dimensions at a custom maximum', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'someChart',
        dimensions: [DIM_A, DIM_B],
        metrics: [METRIC_X],
        maxDimensions: 1,
      }),
    ).toBe('someChart supports a maximum of 1 dimensions');
  });

  it('requires at least one metric', () => {
    expect(
      dimensionMetricValidationError({ displayType: 'barChart', dimensions: [DIM_A], metrics: [] }),
    ).toBe('barChart requires at least one metric');
  });

  it('restricts to a single metric once the dimension maximum is reached', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'barChart',
        dimensions: [DIM_A, DIM_B],
        metrics: [METRIC_X, METRIC_Y],
      }),
    ).toBe('barChart with 2 dimensions supports only a single metric');
  });

  it('allows multiple metrics below the dimension maximum', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'barChart',
        dimensions: [DIM_A],
        metrics: [METRIC_X, METRIC_Y],
      }),
    ).toBeNull();
  });

  it('returns null for a valid combination at the dimension maximum', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'barChart',
        dimensions: [DIM_A, DIM_B],
        metrics: [METRIC_X],
      }),
    ).toBeNull();
  });

  it('does not apply the single-metric restriction when maxDimensions is 1', () => {
    expect(
      dimensionMetricValidationError({
        displayType: 'lineChart',
        dimensions: [DIM_A],
        metrics: [METRIC_X, METRIC_Y],
        maxDimensions: 1,
      }),
    ).toBeNull();
  });
});

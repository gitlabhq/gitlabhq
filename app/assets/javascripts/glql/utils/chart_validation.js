import { __, sprintf } from '~/locale';

// Shared by chart display types that plot up to `maxDimensions` dimensions
// against one or more metrics. Reaching the dimension maximum only leaves
// room for a single metric (a second dimension folds into stacked segments).
// Other display types (e.g. stat's "no dimensions, exactly one metric") have
// a different shape and validate on their own.
export const dimensionMetricValidationError = ({
  displayType,
  dimensions,
  metrics,
  maxDimensions = 2,
}) => {
  if (dimensions.length === 0) {
    return sprintf(__('%{displayType} requires at least one dimension'), { displayType });
  }
  if (dimensions.length > maxDimensions) {
    if (maxDimensions === 1) {
      return sprintf(__('%{displayType} supports exactly one dimension'), { displayType });
    }
    return sprintf(__('%{displayType} supports a maximum of %{maxDimensions} dimensions'), {
      displayType,
      maxDimensions,
    });
  }
  if (metrics.length === 0) {
    return sprintf(__('%{displayType} requires at least one metric'), { displayType });
  }
  if (maxDimensions > 1 && dimensions.length === maxDimensions && metrics.length > 1) {
    return sprintf(
      __('%{displayType} with %{maxDimensions} dimensions supports only a single metric'),
      { displayType, maxDimensions },
    );
  }
  return null;
};

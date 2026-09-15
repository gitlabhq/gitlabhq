import { __, sprintf } from '~/locale';

// Shared by chart display types that plot between `minDimensions` and
// `maxDimensions` dimensions against one or more metrics. Reaching the dimension maximum only leaves
// room for a single metric (a second dimension folds into stacked segments).
// Other display types (e.g. stat's "no dimensions, exactly one metric") have
// a different shape and validate on their own.
export const dimensionMetricValidationError = ({
  displayType,
  dimensions,
  metrics,
  minDimensions = 1,
  maxDimensions = 2,
}) => {
  // At least one dimension is always required, whatever a caller asks for.
  const required = Math.max(minDimensions, 1);
  if (dimensions.length < required) {
    return required <= 1
      ? sprintf(__('%{displayType} requires at least one dimension'), { displayType })
      : sprintf(__('%{displayType} requires %{minDimensions} dimensions'), {
          displayType,
          minDimensions: required,
        });
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

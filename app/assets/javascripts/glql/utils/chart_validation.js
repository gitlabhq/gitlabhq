import { __, sprintf } from '~/locale';

// Shared by display types that plot up to `maxDimensions` dimensions against
// one or more metrics, where reaching the dimension maximum only leaves room
// for a single metric (columnChart, barChart — both fold a second dimension's
// values into stacked segments, which only makes sense for one metric).
// Other display types (e.g. stat's "no dimensions, exactly one metric") have a
// different shape and validate on their own.
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

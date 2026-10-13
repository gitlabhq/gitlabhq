import { s__, sprintf } from '~/locale';
import { dimensionsOf, metricsOf } from '../../../utils/chart_data';
import { valueFormatterFor } from '../../../utils/value_format';
import { NO_VALUE } from './stat';

// A placeholder is usually a plain word, but authors can alias a repeated
// metric with spaces (e.g. `%{p95 duration}`). Handled here instead of
// sprintf because sprintf's `\w+` pattern silently ignores those names.
const PLACEHOLDER_REGEX = /%\{([^}]+)\}/g;

/** The placeholder names a description interpolates, in the order they appear. */
export const placeholdersIn = (description) =>
  Array.from(String(description ?? '').matchAll(PLACEHOLDER_REGEX), ([, key]) => key);

/**
 * Fills `%{fieldKey}` placeholders in a description with formatted values from the query's
 * single row, so copy like "%{acceptedCount} of %{shownCount} suggestions" reads off the
 * response instead of being hardcoded. Each value formats by its own metric's unit.
 */
export const interpolateDescription = (description, fields, row) => {
  if (!description) return description;

  const values = Object.fromEntries(
    fields.map((field) => {
      const value = row?.[field.key];
      return [field.key, value == null ? NO_VALUE : valueFormatterFor(field)(value)];
    }),
  );

  // Values are formatted numbers rendered as text, so escaping them would only turn
  // separators into entities.
  return description.replace(PLACEHOLDER_REGEX, (match, key) =>
    key in values ? values[key] : match,
  );
};

/** The block error for a placeholder naming a metric the query does not select. */
export const unknownPlaceholderError = (description, metrics) => {
  const metricKeys = new Set(metrics.map(({ key }) => key));
  const unknown = placeholdersIn(description).find((key) => !metricKeys.has(key));

  if (!unknown) return null;

  return sprintf(s__('Glql|Unknown description placeholder: `%{placeholder}`.'), {
    placeholder: unknown,
  });
};

/**
 * The block error for placeholders in a query with dimensions. A placeholder reads the first
 * row, so it would show one group's value as if it covered them all.
 */
const dimensionPlaceholderError = (description, dimensions) => {
  if (!dimensions.length || !placeholdersIn(description).length) return null;

  return s__('Glql|Description placeholders cannot be used with dimensions.');
};

/**
 * The description a bar list or table shows above its rows. `null` while a placeholder
 * description waits for the first row, since every placeholder would read as a missing value.
 */
export const listDescriptionFor = ({ description, fields, data, loading }) => {
  const row = data?.nodes?.[0];
  if (!row && loading && placeholdersIn(description).length) return null;

  return interpolateDescription(description, metricsOf(fields), row);
};

/** The block error for a bar list or table description the query cannot fill. */
export const listDescriptionError = (description, fields) =>
  unknownPlaceholderError(description, metricsOf(fields)) ??
  dimensionPlaceholderError(description, dimensionsOf(fields));

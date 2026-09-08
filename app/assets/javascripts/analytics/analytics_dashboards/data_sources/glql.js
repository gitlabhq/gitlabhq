import { s__ } from '~/locale';
import { millisecondsPerDay, nDaysBefore, toISODateFormat } from '~/lib/utils/datetime_utility';
import { resolveDateRangeFilter } from '~/explore/analytics_dashboards/components/utils';
import { DATE_RANGE_OPTION_LAST_30_DAYS } from '~/explore/analytics_dashboards/components/constants';

// A GLQL query names its own date field (`timestamp` here, `merged` there), so the panel
// declares where the dashboard's date range goes instead of this source guessing:
//   query: type = AiUsageEvent and timestamp >= "%{startDate}" and timestamp <= "%{endDate}"
const dateRangeVariables = ({ startDate, endDate }) => ({
  startDate: toISODateFormat(startDate, true),
  endDate: toISODateFormat(endDate, true),
});

// Counted in UTC days like the shift and formatting below: a local-day count gains or loses
// a day when a DST change falls inside the window.
const utcDayDifference = (startDate, endDate) => {
  const utcDay = (date) => Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());

  return (utcDay(endDate) - utcDay(startDate)) / millisecondsPerDay;
};

// A preset carries its previous window already; only a custom range derives one. GLQL reads
// both bounds as whole days, so the length counts both ends and the previous window closes
// the day before this one opens.
const previousDateRange = ({ startDate, endDate, previousRange }) => {
  if (previousRange) return previousRange;

  const length = utcDayDifference(startDate, endDate) + 1;

  return {
    startDate: nDaysBefore(startDate, length, { utc: true }),
    endDate: nDaysBefore(endDate, length, { utc: true }),
  };
};

// Only the names given are substituted, so any other `%{...}` the query holds reaches the
// GLQL compiler as the author wrote it.
const interpolate = (glql, variables) =>
  Object.entries(variables).reduce(
    (query, [name, value]) => query.replaceAll(`%{${name}}`, value),
    glql,
  );

// Both bounds have to move for the previous window to be a window: a query that pins only
// its start would run its comparison up to today, over the very period it is compared with.
const usesWholeDateRange = (glql, variables) =>
  Object.keys(variables).every((name) => glql.includes(`%{${name}}`));

/**
 * Passes a GLQL query string through to the visualization, resolving the dashboard's
 * date range filter into it.
 *
 * Unlike other data sources, GLQL panels don't fetch data here: the `GlqlResolver`
 * rendered by the `Glql` visualization parses and executes the query itself. This
 * source surfaces the query string (stored in the panel's `data.query`) as the `data`
 * prop the visualization receives, with any date range placeholders substituted first.
 *
 * GLQL reads an absolute bound as the whole day (`timestamp <= "2026-09-02"` compiles to
 * `timestampTo: "2026-09-02 23:59"`), so the range needs no end-exclusive adjustment.
 *
 * A query with no placeholders is returned untouched, so GLQL panels on dashboards
 * without a date range filter keep the window their own query sets.
 *
 * With `showTrends` in the visualization options, the same query over the window
 * immediately before the selected one is handed down as the `comparisonQuery`
 * visualization option, which the stat display renders as a trend.
 */
export default function fetch({
  query: { glql = '' } = {},
  filters = {},
  visualizationOptions: { showTrends = false } = {},
  setVisualizationOverrides = () => {},
} = {}) {
  if (typeof glql !== 'string') {
    throw new Error(s__('Glql|GLQL query must be a string.'));
  }

  const dateRange = resolveDateRangeFilter(filters, DATE_RANGE_OPTION_LAST_30_DAYS);
  const variables = dateRangeVariables(dateRange);

  if (showTrends && usesWholeDateRange(glql, variables)) {
    setVisualizationOverrides({
      visualizationOptionOverrides: {
        comparisonQuery: interpolate(glql, dateRangeVariables(previousDateRange(dateRange))),
      },
    });
  }

  return interpolate(glql, variables);
}

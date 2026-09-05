import { s__ } from '~/locale';
import { toISODateFormat } from '~/lib/utils/datetime_utility';
import { resolveDateRangeFilter } from '~/explore/analytics_dashboards/components/utils';
import { DATE_RANGE_OPTION_LAST_30_DAYS } from '~/explore/analytics_dashboards/components/constants';

// A GLQL query names its own date field (`timestamp` here, `merged` there), so the panel
// declares where the dashboard's date range goes instead of this source guessing:
//   query: type = AiUsageEvent and timestamp >= "%{startDate}" and timestamp <= "%{endDate}"
const dateRangeVariables = (filters) => {
  const { startDate, endDate } = resolveDateRangeFilter(filters, DATE_RANGE_OPTION_LAST_30_DAYS);

  return {
    startDate: toISODateFormat(startDate, true),
    endDate: toISODateFormat(endDate, true),
  };
};

// Only the names given are substituted, so any other `%{...}` the query holds reaches the
// GLQL compiler as the author wrote it.
const interpolate = (glql, variables) =>
  Object.entries(variables).reduce(
    (query, [name, value]) => query.replaceAll(`%{${name}}`, value),
    glql,
  );

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
 */
export default function fetch({ query: { glql = '' } = {}, filters = {} } = {}) {
  if (typeof glql !== 'string') {
    throw new Error(s__('Glql|GLQL query must be a string.'));
  }

  return interpolate(glql, dateRangeVariables(filters));
}

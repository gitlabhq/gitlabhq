import { trendChangeFor } from './trend';

// Reserved keys for the derived trend column. A compiled GLQL field key comes from query
// text, which cannot produce these, so they can never collide with a real field.
export const TREND_CHANGE_KEY = '__trendChange';
export const TREND_PREVIOUS_KEY = '__trendPrevious';

// An object dimension value carrying no `id` names a record that exists but cannot be told
// from another of its kind, so a row holding one never pairs. An absent value is different:
// it is the query's own NULL bucket, so it keeps an ordinary key and pairs like any other.
const UNIDENTIFIED = Symbol('unidentified');

// Identity, deliberately not the display label: two distinct records can share a label (two
// users named "Alex Smith"), and pairing on the label compares one against the other.
const identityOf = (value) => {
  if (value == null) return null;
  if (typeof value !== 'object') return String(value);

  return value.id ?? UNIDENTIFIED;
};

// Null when the row holds a value nothing can name, which has to short-circuit: JSON renders
// a symbol as null too, so an absent value would otherwise key alike. It keeps an absent
// value apart from any string that reads like one.
const rowKeyOf = (node, dimensions) => {
  const identities = dimensions.map((dimension) => identityOf(node[dimension.key]));
  if (identities.includes(UNIDENTIFIED)) return null;

  return JSON.stringify(identities);
};

// Unidentified rows are left out, so their null key is never a count anything can match.
const rowKeyCountsOf = (nodes, dimensions) =>
  nodes.reduce((counts, node) => {
    const key = rowKeyOf(node, dimensions);
    if (key === null) return counts;

    return counts.set(key, (counts.get(key) ?? 0) + 1);
  }, new Map());

/**
 * True when any dimension buckets by date. Bucket values are different dates in the shifted
 * window, so joining the two periods on dimension values matches nothing. Comparing a bucket
 * against the same bucket one period back is the engine's job (`lagged_count`), not ours.
 */
export const hasTemporalDimension = (dimensions) =>
  dimensions.some((dimension) => Boolean(dimension?.parameters?.granularity));

/**
 * Pairs each row with its counterpart in the previous period and materialises the change in
 * `metric` onto a copy of the row.
 *
 * A row pairs only when its identity belongs to it alone in both periods. One blank row is
 * still a bucket of its own — `project` is null for every flow started outside a project —
 * so it keeps its trend; several are a crowd nothing can be picked out of, which is what a
 * `group` dimension produces for namespaces it cannot resolve.
 *
 * The change lands on the row itself so the table can sort by it through the ordinary field
 * sorter. Rows with no counterpart get null, which reads as "unknown" rather than "no change"
 * and sorts last. Note the previous-period result is fetched once and never paginated, so a
 * row past its extent is legitimately unknown too.
 */
export const withTrendValues = (nodes, { comparisonNodes = [], dimensions, metric }) => {
  const currentCounts = rowKeyCountsOf(nodes, dimensions);
  const previousCounts = rowKeyCountsOf(comparisonNodes, dimensions);

  const previousByRowKey = new Map();
  comparisonNodes.forEach((node) => {
    const key = rowKeyOf(node, dimensions);
    if (previousCounts.get(key) === 1) previousByRowKey.set(key, node[metric.key]);
  });

  return nodes.map((node) => {
    const key = rowKeyOf(node, dimensions);
    const previousValue = (currentCounts.get(key) === 1 ? previousByRowKey.get(key) : null) ?? null;

    return {
      ...node,
      [TREND_PREVIOUS_KEY]: previousValue,
      [TREND_CHANGE_KEY]: trendChangeFor(node[metric.key], previousValue),
    };
  });
};

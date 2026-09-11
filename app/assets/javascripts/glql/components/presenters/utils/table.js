import { trendChangeFor } from './trend';

// Reserved keys for the derived trend column. A compiled GLQL field key comes from query
// text, which cannot produce these, so they can never collide with a real field.
export const TREND_CHANGE_KEY = '__trendChange';
export const TREND_PREVIOUS_KEY = '__trendPrevious';

// An object dimension value carrying no `id` cannot be told apart from another of its kind,
// so a row holding one is left unpaired rather than matched on a display label.
const UNIDENTIFIED = Symbol('unidentified');

// Identity, deliberately not the display label: two distinct records can share a label (two
// users named "Alex Smith"), and pairing on the label compares one against the other.
const identityOf = (value) => {
  if (value == null) return null;
  if (typeof value !== 'object') return String(value);

  return value.id ?? UNIDENTIFIED;
};

// Null when the row cannot be identified. JSON keeps a null dimension distinct from any
// string, so a blank never pairs with a value that happens to read like one.
const rowKeyOf = (node, dimensions) => {
  const identities = dimensions.map((dimension) => identityOf(node[dimension.key]));
  if (identities.includes(UNIDENTIFIED)) return null;

  return JSON.stringify(identities);
};

/**
 * True when every identifiable row in `nodes` has a distinct identity.
 *
 * Identity comes from a record's `id` rather than its label, so a collision here means two
 * rows genuinely are the same thing, and pairing either of them across periods would be a
 * guess. Unidentifiable rows are excluded because they never pair at all.
 *
 * Callers check both periods: a duplicate on either side mispairs the other.
 */
export const hasUniqueRowKeys = (nodes, dimensions) => {
  const keys = nodes.map((node) => rowKeyOf(node, dimensions)).filter((key) => key !== null);

  return new Set(keys).size === keys.length;
};

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
 * The change lands on the row itself so the table can sort by it through the ordinary field
 * sorter. Rows with no counterpart get null, which reads as "unknown" rather than "no change"
 * and sorts last. Note the previous-period result is fetched once and never paginated, so a
 * row past its extent is legitimately unknown too.
 */
export const withTrendValues = (nodes, { comparisonNodes = [], dimensions, metric }) => {
  const previousByRowKey = new Map();
  comparisonNodes.forEach((node) => {
    const key = rowKeyOf(node, dimensions);
    if (key !== null) previousByRowKey.set(key, node[metric.key]);
  });

  return nodes.map((node) => {
    const key = rowKeyOf(node, dimensions);
    const previousValue = (key === null ? null : previousByRowKey.get(key)) ?? null;

    return {
      ...node,
      [TREND_PREVIOUS_KEY]: previousValue,
      [TREND_CHANGE_KEY]: trendChangeFor(node[metric.key], previousValue),
    };
  });
};

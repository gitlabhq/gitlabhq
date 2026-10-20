import { badgeVariantOptions } from '@gitlab/ui/src/utils/constants';
import { __, formatNumber, sprintf } from '~/locale';
import { valueFormatterFor } from '../../../utils/value_format';
import { positiveDirectionFor } from './stat';

// Rounded half away from zero to the one decimal a trend renders, so the arrow and colour
// agree with the text: 10,004 against 10,000 reads `0%` with no arrow rather than an up arrow.
const roundChange = (change) => (Math.sign(change) * Math.round(Math.abs(change) * 1000)) / 1000;

/**
 * Resolves the signed fractional change from `previousValue` to `value`, rounded to the
 * precision a trend renders, or null when there is no number to show. Shared with callers
 * that sort by the change, so the ordering can never disagree with the rendered value.
 */
export const trendChangeFor = (value, previousValue) => {
  if (value == null || previousValue == null) return null;
  if (value === previousValue) return 0;
  // A move away from 0 has no percentage; callers label it as new instead.
  if (previousValue === 0) return null;

  return roundChange((value - previousValue) / previousValue);
};

/**
 * Formats a change as an unsigned percentage. The sign is carried by the arrow, the colour
 * and the tooltip, so a caller that renders the number alone must supply its own direction.
 */
export const formatChange = (change) =>
  formatNumber(Math.abs(change), { style: 'percent', maximumFractionDigits: 1 });

/**
 * Formats a change as a signed percentage (`+7%`, `-4%`, `0%`), for a label with room for
 * neither an arrow nor a tooltip to carry the direction.
 */
export const formatSignedChange = (change) =>
  formatNumber(change, { style: 'percent', maximumFractionDigits: 1, signDisplay: 'exceptZero' });

// Reserved keys a trend adds to each row. A compiled GLQL field key comes from query text,
// which cannot produce these, so they can never collide with a real field.
export const TREND_CHANGE_KEY = '__trendChange';
export const TREND_PREVIOUS_KEY = '__trendPrevious';
// Holds a row's badge config, kept apart from TREND_CHANGE_KEY because only that one is
// sortable.
export const TREND_KEY = '__trend';

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

const TREND_ICON_BY_DIRECTION = { up: 'arrow-up', down: 'arrow-down' };

/** The GlSingleStat props a trend fills in. */
export const TREND_KEYS = ['metaText', 'metaIcon', 'metaTooltip', 'variant'];

// The arrow icon and badge colour convey direction visually but are not announced, so the
// tooltip spells it out for screen reader users.
const trendTooltipFor = (direction, change, value) => {
  if (direction === 'up') {
    return sprintf(__('Up %{change} from %{value} in the previous period'), { change, value });
  }
  if (direction === 'down') {
    return sprintf(__('Down %{change} from %{value} in the previous period'), { change, value });
  }
  return sprintf(__('No change from %{value} in the previous period'), { value });
};

/**
 * Resolves the GlSingleStat meta badge describing how `value` moved from `previousValue`, as
 * display config the block's own `displayConfig` can override. Null when either value is
 * missing, since there is nothing to compare.
 */
export const trendPresentationFor = (source, metric, { value, previousValue }) => {
  if (value == null || previousValue == null) return null;

  const formattedPrevious = valueFormatterFor(metric)(previousValue);

  // A move from 0 has no percentage, so the badge says the metric is new. It stays neutral
  // because the size of the move is unknown, but the arrow still shows its direction.
  if (previousValue === 0 && value !== 0) {
    return {
      metaText: __('New'),
      metaIcon: TREND_ICON_BY_DIRECTION.up,
      metaTooltip: sprintf(__('Up from %{value} in the previous period'), {
        value: formattedPrevious,
      }),
      variant: badgeVariantOptions.neutral,
    };
  }

  const change = trendChangeFor(value, previousValue);
  let direction = null;
  if (change > 0) direction = 'up';
  else if (change < 0) direction = 'down';

  const positiveDirection = positiveDirectionFor(source, metric);
  let variant = badgeVariantOptions.neutral;
  if (direction && positiveDirection) {
    variant =
      direction === positiveDirection ? badgeVariantOptions.success : badgeVariantOptions.danger;
  }

  const formattedChange = formatChange(change);
  return {
    metaText: sprintf(__('%{change} vs prior'), { change: formattedChange }),
    metaIcon: TREND_ICON_BY_DIRECTION[direction] ?? null,
    metaTooltip: trendTooltipFor(direction, formattedChange, formattedPrevious),
    variant,
  };
};

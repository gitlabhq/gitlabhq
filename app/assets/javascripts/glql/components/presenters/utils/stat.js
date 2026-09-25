import { badgeVariantOptions } from '@gitlab/ui/src/utils/constants';
import { __, sprintf } from '~/locale';
import { baseFieldKeyOf } from '../../../utils/chart_data';
import { unitFor, valueFormatterFor } from '../../../utils/value_format';
import { formatChange, trendChangeFor } from './trend';

const POSITIVE_DIRECTION_BY_UNIT = {
  count: 'up',
  rate: 'up',
  duration: 'down',
};

// Keyed by the source `glql.compile` resolves, because one metric name has a different
// subject in each source. Copy mirrors the tables in doc/user/glql/data_sources/.
const METRIC_PRESENTATION = {
  CodeSuggestions: {
    acceptanceRate: { description: __('Ratio of accepted to shown suggestions.') },
    acceptedCount: { description: __('Number of accepted suggestions.') },
    rejectedCount: {
      description: __('Number of rejected suggestions.'),
      positiveDirection: 'down',
    },
    shownCount: { description: __('Number of suggestions shown to users.') },
    suggestionSizeSum: { description: __('Total volume of suggestions.') },
    totalCount: { description: __('Total number of suggestions.') },
    usersCount: { description: __('Number of unique users.') },
  },
  AiUsageEvents: {
    featuresCount: { description: __('Number of unique features used.') },
    previousPeriodUsersCount: {
      description: __('Number of unique users in the previous period.'),
    },
    returningUsersCount: {
      description: __('Number of users active in both the current and previous period.'),
    },
    totalCount: { description: __('Total number of events.') },
    usersCount: { description: __('Number of unique users.') },
  },
  Pipelines: {
    canceledRate: {
      description: __('Ratio of canceled pipelines to finished pipelines.'),
      positiveDirection: 'down',
    },
    durationMax: { description: __('Longest pipeline duration, in seconds.') },
    durationMean: { description: __('Average pipeline duration, in seconds.') },
    durationMin: { description: __('Shortest pipeline duration, in seconds.') },
    durationQuantile: { description: __('Pipeline duration quantile, in seconds.') },
    durationSum: { description: __('Total duration of all pipelines, in seconds.') },
    failureRate: {
      description: __('Ratio of failed pipelines to finished pipelines.'),
      positiveDirection: 'down',
    },
    skippedRate: {
      description: __('Ratio of skipped pipelines to finished pipelines.'),
      positiveDirection: 'down',
    },
    successRate: { description: __('Ratio of successful pipelines to finished pipelines.') },
    totalCount: {
      description: __('Total number of pipelines, including in-progress ones.'),
    },
  },
  MergeRequests: {
    acceptanceRate: { description: __('Share of merge requests that were merged.') },
    throughputCount: { description: __('Number of merged merge requests.') },
    timeToMergeMax: { description: __('Longest time from creation to merge, in seconds.') },
    timeToMergeMean: { description: __('Average time from creation to merge, in seconds.') },
    timeToMergeMin: { description: __('Shortest time from creation to merge, in seconds.') },
    timeToMergeQuantile: { description: __('Time from creation to merge, in seconds.') },
    timeToMergeSum: {
      description: __(
        'Total time from creation to merge across all merged merge requests, in seconds.',
      ),
    },
    totalCount: { description: __('Total number of merge requests.') },
  },
  Contributions: {
    totalCount: { description: __('Total number of contributions.') },
    usersCount: { description: __('Number of unique contributors.') },
  },
  DuoWorkflows: {
    churnedUsersCount: {
      description: __(
        'Number of unique users who ran a flow in the previous period but not in this one.',
      ),
      positiveDirection: 'down',
    },
    closedMrCountMax: {
      description: __('Most closed merge requests created by a single flow.'),
      positiveDirection: 'down',
    },
    closedMrCountMean: {
      description: __('Average closed merge requests created per flow.'),
      positiveDirection: 'down',
    },
    closedMrCountMin: {
      description: __('Fewest closed merge requests created by a single flow.'),
      positiveDirection: 'down',
    },
    closedMrCountQuantile: {
      description: __('Closed merge requests created per flow at a given quantile.'),
      positiveDirection: 'down',
    },
    closedMrCountSum: {
      description: __('Total closed merge requests created by all flows.'),
      positiveDirection: 'down',
    },
    createdMrCountMax: { description: __('Most merge requests created by a single flow.') },
    createdMrCountMean: { description: __('Average merge requests created per flow.') },
    createdMrCountMin: { description: __('Fewest merge requests created by a single flow.') },
    createdMrCountQuantile: {
      description: __('Merge requests created per flow at a given quantile.'),
    },
    createdMrCountSum: { description: __('Total merge requests created by all flows.') },
    creditsPerMergedMrRatio: {
      description: __('Credits used per merge request created by a flow and later merged.'),
      positiveDirection: 'down',
    },
    creditsUsedMax: { description: __('Most credits used by a single flow.') },
    creditsUsedMean: { description: __('Average credits used per flow.') },
    creditsUsedMin: { description: __('Fewest credits used by a single flow.') },
    creditsUsedQuantile: { description: __('Credits used per flow at a given quantile.') },
    creditsUsedSum: { description: __('Total credits used by all flows.') },
    flowTypesCount: { description: __('Number of unique flow types.') },
    joinedUsersCount: {
      description: __(
        'Number of unique users who ran a flow in this period but not in the previous one.',
      ),
    },
    mergedMrCountMax: { description: __('Most merged merge requests created by a single flow.') },
    mergedMrCountMean: { description: __('Average merged merge requests created per flow.') },
    mergedMrCountMin: { description: __('Fewest merged merge requests created by a single flow.') },
    mergedMrCountQuantile: {
      description: __('Merged merge requests created per flow at a given quantile.'),
    },
    mergedMrCountSum: { description: __('Total merged merge requests created by all flows.') },
    openMrCountMax: { description: __('Most open merge requests created by a single flow.') },
    openMrCountMean: { description: __('Average open merge requests created per flow.') },
    openMrCountMin: { description: __('Fewest open merge requests created by a single flow.') },
    openMrCountQuantile: {
      description: __('Open merge requests created per flow at a given quantile.'),
    },
    openMrCountSum: { description: __('Total open merge requests created by all flows.') },
    previousPeriodUsersCount: { description: __('Number of unique users in the previous period.') },
    projectsCount: { description: __('Number of unique projects.') },
    returningUsersCount: {
      description: __('Number of unique users who also ran a flow in the previous period.'),
    },
    totalCount: {
      description: __('Total number of flows, optionally filtered by status.'),
    },
    usersCount: { description: __('Number of unique users.') },
  },
};

const presentationFor = (source, metric) =>
  METRIC_PRESENTATION[source]?.[baseFieldKeyOf(metric)] ?? {};

// `displayConfig` comes from user-authored YAML, so a scalar can arrive as a number or a
// boolean. GlSingleStat's props are strings and would log a type warning without this.
const asString = (value) => (value == null ? null : String(value));

/**
 * Returns 'up' or 'down' for the direction of change that is good for this metric of this
 * data source, or null when the metric has no registered unit.
 */
export const positiveDirectionFor = (source, metric) =>
  presentationFor(source, metric).positiveDirection ??
  POSITIVE_DIRECTION_BY_UNIT[unitFor(baseFieldKeyOf(metric))] ??
  null;

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

// Rendered in place of a value the query did not return. Aggregations over an empty set
// can omit the node entirely, so this distinguishes "no data" from a 0.
export const NO_VALUE = '\u2014';

/**
 * Resolves the GlSingleStat props for a stat display. `displayConfig` always wins over a
 * derived default, and an empty `description` suppresses the derived copy.
 *
 * `variant` is returned as authored rather than coerced to a valid value, so the presenter
 * can reject an unknown one as a GLQL block error.
 */
export const statPresentationFor = (source, metric, displayConfig) => {
  const config = displayConfig ?? {};
  const metaText = asString(config.metaText);

  return {
    // A block's own `title:` and a dashboard panel each render a heading already, so the
    // stat's title stays empty unless a block asks for one. "Copy contents" supplies the
    // metric label separately, since that heading is outside the copied element.
    title: asString(config.title) ?? '',
    unit: asString(config.unit),
    description:
      asString(config.description) ?? presentationFor(source, metric).description ?? null,
    metaText,
    metaIcon: asString(config.metaIcon),
    // The tooltip hangs off the meta badge, which GlSingleStat only renders with `metaText`.
    metaTooltip: metaText ? (asString(config.metaTooltip) ?? '') : '',
    titleIcon: asString(config.titleIcon),
    variant: asString(config.variant) ?? badgeVariantOptions.neutral,
  };
};

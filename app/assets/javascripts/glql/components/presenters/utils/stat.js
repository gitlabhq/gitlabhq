import { badgeVariantOptions } from '@gitlab/ui/src/utils/constants';
import { __ } from '~/locale';
import { baseFieldKeyOf } from '../../../utils/chart_data';
import { unitFor } from '../../../utils/value_format';

// Nothing renders this yet: it exists so trend colouring (glql#102) reads one mapping
// instead of defining a competing one.
const POSITIVE_DIRECTION_BY_UNIT = {
  count: 'up',
  rate: 'up',
  duration: 'down',
  durationMs: 'down',
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
    durationQuantile: { description: __('Pipeline duration quantile, in seconds.') },
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
    throughputCount: { description: __('Number of merged merge requests.') },
    timeToMergeQuantile: { description: __('Time from creation to merge.') },
    totalCount: { description: __('Total number of merge requests.') },
  },
  Contributions: {
    totalCount: { description: __('Total number of contributions.') },
    usersCount: { description: __('Number of unique contributors.') },
  },
};

const presentationFor = (source, metric) =>
  METRIC_PRESENTATION[source]?.[baseFieldKeyOf(metric)] ?? {};

// `displayConfig` comes from user-authored YAML, so a scalar can arrive as a number or a
// boolean. GlSingleStat's props are strings and would log a type warning without this.
const asString = (value) => (value == null ? null : String(value));

/**
 * Returns 'up' or 'down' for the direction of change that is good for this metric of this
 * data source, or null when the metric has no registered unit. Read by trend rendering
 * (glql#102).
 */
export const positiveDirectionFor = (source, metric) =>
  presentationFor(source, metric).positiveDirection ??
  POSITIVE_DIRECTION_BY_UNIT[unitFor(baseFieldKeyOf(metric))] ??
  null;

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
    // stat's title stays empty unless a block asks for one.
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

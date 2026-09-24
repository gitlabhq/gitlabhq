import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import StatusPresenter from 'ee_else_ce/glql/components/presenters/status.vue';
import HealthPresenter from 'ee_else_ce/glql/components/presenters/health.vue';

import IssuablePresenter from './issuable.vue';
import MilestonePresenter from './milestone.vue';
import ProjectPresenter from './project.vue';
import UserPresenter from './user.vue';
import UserAvatarPresenter from './user_avatar.vue';
import LabelPresenter from './label.vue';
import TypePresenter from './type.vue';
import StatePresenter from './state.vue';
import HtmlPresenter from './html.vue';
import CiItemPresenter from './ci_item.vue';
import CiStatusPresenter from './ci_status.vue';
import CodePresenter from './code.vue';
import DateBucketPresenter from './date_bucket.vue';
import DurationPresenter from './duration.vue';
import NamedTextPresenter from './named_text.vue';
import NullPresenter from './null.vue';
import BoolPresenter from './bool.vue';
import CollectionPresenter from './collection.vue';
import LinkPresenter from './link.vue';
import TimePresenter from './time.vue';
import TextPresenter from './text.vue';
import UrlPresenter from './url.vue';
import PercentagePresenter from './percentage.vue';
import NumberPresenter from './number.vue';
import CreditsPresenter from './credits.vue';

// A registry value is either a Vue component (used for all variants/typenames)
// or a plain object whose keys are variant names / parent typenames. Vue
// components carry a `name` option; plain objects don't.
const isVueComponent = (value) => Boolean(value?.name);

// Maps GraphQL __typename to presenters. Values can be:
// - A presenter component (used for all variants)
// - An object keyed by variant name (lowercase, e.g. `compact`) with an
//   optional `default` key as the fallback. May also carry `titleField` —
//   the field key that holds the item's title for list/table heading
//   promotion (defaults to `title` when omitted). A field_spec invariant
//   guards against `titleField` clashing with `presentersByFieldKey` keys.
export const presentersByObjectType = {
  MergeRequest: IssuablePresenter,
  Issue: IssuablePresenter,
  Epic: IssuablePresenter,
  WorkItem: IssuablePresenter,
  Milestone: MilestonePresenter,
  MergeRequestAuthor: UserPresenter,
  MergeRequestReviewer: UserPresenter,
  MergeRequestAssignee: UserPresenter,
  UserCore: UserPresenter,
  Label: LabelPresenter,
  Iteration: IterationPresenter,
  WorkItemStatus: StatusPresenter,
  WorkItemType: TypePresenter,
  Project: {
    default: ProjectPresenter,
    compact: LinkPresenter,
    titleField: 'name',
  },
  Pipeline: CiItemPresenter,
  CiJob: CiItemPresenter,
  CiStage: NamedTextPresenter,
  Group: LinkPresenter,
};

// Maps field keys to presenters. Values can be:
// - A presenter component (used for all parent types and variants)
// - An object whose keys can mix variant names (lowercase, e.g. `compact`)
//   and parent __typename (PascalCase, e.g. `CiJob`), with an optional
//   `default` key as the fallback. Variant matches take precedence over
//   typename matches.
export const presentersByFieldKey = {
  health: HealthPresenter,
  healthStatus: HealthPresenter,
  state: StatePresenter,
  status: {
    Pipeline: CiStatusPresenter,
    CiJob: CiStatusPresenter,
    PipelinesAggregationResponseDimensions: CiStatusPresenter,
  },
  description: HtmlPresenter,
  descriptionHtml: HtmlPresenter,
  lastComment: HtmlPresenter,
  duration: DurationPresenter,
  queuedDuration: DurationPresenter,
  webPath: UrlPresenter,
  webUrl: UrlPresenter,
  path: { Pipeline: UrlPresenter },
  commitPath: UrlPresenter,
  browseArtifactsPath: UrlPresenter,
  sourceBranch: CodePresenter,
  targetBranch: CodePresenter,
  ref: CodePresenter,
  refName: CodePresenter,
  sha: CodePresenter,
  shortSha: CodePresenter,
  refPath: { CiJob: UrlPresenter, default: CodePresenter },
  type: TypePresenter,
  user: {
    DuoCodeSuggestionsAggregationResponseDimensions: UserAvatarPresenter,
    DuoUsageEventsAggregationResponseDimensions: UserAvatarPresenter,
    AgentPlatformSessionsAggregationResponseDimensions: UserAvatarPresenter,
    DuoWorkflowsAggregationResponseDimensions: UserAvatarPresenter,
    default: UserPresenter,
    compact: UserPresenter,
  },
  acceptanceRate: PercentagePresenter,
  successRate: PercentagePresenter,
  failureRate: PercentagePresenter,
  canceledRate: PercentagePresenter,
  skippedRate: PercentagePresenter,
  completionRate: PercentagePresenter,
  acceptedCount: NumberPresenter,
  rejectedCount: NumberPresenter,
  shownCount: NumberPresenter,
  totalCount: NumberPresenter,
  usersCount: NumberPresenter,
  finishedCount: NumberPresenter,
  projectsCount: NumberPresenter,
  suggestionSizeSum: NumberPresenter,
  throughputCount: NumberPresenter,
  featuresCount: NumberPresenter,
  returningUsersCount: NumberPresenter,
  previousPeriodUsersCount: NumberPresenter,
  joinedUsersCount: NumberPresenter,
  churnedUsersCount: NumberPresenter,
  flowTypesCount: NumberPresenter,
  createdMrCountMin: NumberPresenter,
  createdMrCountMax: NumberPresenter,
  createdMrCountMean: NumberPresenter,
  createdMrCountSum: NumberPresenter,
  createdMrCountQuantile: NumberPresenter,
  mergedMrCountMin: NumberPresenter,
  mergedMrCountMax: NumberPresenter,
  mergedMrCountMean: NumberPresenter,
  mergedMrCountSum: NumberPresenter,
  mergedMrCountQuantile: NumberPresenter,
  closedMrCountMin: NumberPresenter,
  closedMrCountMax: NumberPresenter,
  closedMrCountMean: NumberPresenter,
  closedMrCountSum: NumberPresenter,
  closedMrCountQuantile: NumberPresenter,
  openMrCountMin: NumberPresenter,
  openMrCountMax: NumberPresenter,
  openMrCountMean: NumberPresenter,
  openMrCountSum: NumberPresenter,
  openMrCountQuantile: NumberPresenter,
  creditsUsedMin: CreditsPresenter,
  creditsUsedMax: CreditsPresenter,
  creditsUsedMean: CreditsPresenter,
  creditsUsedSum: CreditsPresenter,
  creditsUsedQuantile: CreditsPresenter,
  creditsPerMergedMrRatio: CreditsPresenter,
  durationQuantile: DurationPresenter,
  durationMean: DurationPresenter,
  durationMin: DurationPresenter,
  durationMax: DurationPresenter,
  durationSum: DurationPresenter,
  timeToMergeQuantile: DurationPresenter,
  timeToMergeMean: DurationPresenter,
  timeToMergeMin: DurationPresenter,
  timeToMergeMax: DurationPresenter,
  timeToMergeSum: DurationPresenter,
};

// Returns the field key that holds the title for the given __typename,
// falling back to `title` when the type doesn't declare an alias.
export const titleFieldFor = (typename) => {
  return presentersByObjectType[typename]?.titleField ?? 'title';
};

// The title field hands the whole item to the type-routed presenter; other
// field keys resolve to that field's value. Match on the base field key so an
// unrelated field aliased `as "title"` still resolves to its own value.
export const dataForField = (item, fieldKey, presenterKey = '') => {
  // eslint-disable-next-line no-underscore-dangle
  if (!fieldKey || (presenterKey || fieldKey) === titleFieldFor(item?.__typename)) return item;
  return item[fieldKey];
};

const presenterByObjectType = (field, variant) => {
  // eslint-disable-next-line no-underscore-dangle
  const byType = presentersByObjectType[field?.__typename];
  if (!byType) return null;
  if (isVueComponent(byType)) return byType;
  return (variant !== 'default' && byType[variant]) || byType.default;
};

const presenterByFieldKey = (fieldKey, item, variant) => {
  const byKey = presentersByFieldKey[fieldKey];
  if (!byKey) return null;
  if (isVueComponent(byKey)) return byKey;
  return (
    (variant !== 'default' && byKey[variant]) ||
    // eslint-disable-next-line no-underscore-dangle
    byKey[item?.__typename] ||
    byKey.default
  );
};

const presenterByPrimitiveType = (field) => {
  if (typeof field === 'boolean') return BoolPresenter;
  if (Array.isArray(field?.nodes)) return CollectionPresenter;
  if (typeof field === 'object') return LinkPresenter;
  if (typeof field === 'string' && field.match(/^\d{4}-\d{2}-\d{2}/)) return TimePresenter;
  return TextPresenter;
};

// Without this, bucket values hit the primitive fallback and render as relative time.
// Only strings qualify: the presenter stringifies non-bucket strings unchanged, while
// objects and numbers on a future non-date field keep their regular dispatch.
const isDateBucket = (field, parameters) =>
  Boolean(parameters.granularity) && typeof field === 'string';

// Resolves a presenter for (item, fieldKey) via: null → bucket → field-key → typename → primitive.
// `fieldKey` is the data key for value lookup; `presenterKey` (falls back to `fieldKey`)
// is used for `presentersByFieldKey` — needed because aliased fields store data under
// the alias, not the base field key.
export const presenterFor = (
  item,
  fieldKey,
  { variant = 'default', presenterKey = '', parameters = {} } = {},
) => {
  const field = dataForField(item, fieldKey, presenterKey);
  if (field == null) return NullPresenter;
  if (isDateBucket(field, parameters)) return DateBucketPresenter;
  return (
    presenterByFieldKey(presenterKey || fieldKey, item, variant) ||
    presenterByObjectType(field, variant) ||
    presenterByPrimitiveType(field)
  );
};

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
    FinishedPipelinesAggregationResponseDimensions: CiStatusPresenter,
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
    default: UserPresenter,
    compact: UserPresenter,
  },
  acceptanceRate: PercentagePresenter,
  successRate: PercentagePresenter,
  failureRate: PercentagePresenter,
  canceledRate: PercentagePresenter,
  skippedRate: PercentagePresenter,
  acceptedCount: NumberPresenter,
  rejectedCount: NumberPresenter,
  shownCount: NumberPresenter,
  totalCount: NumberPresenter,
  usersCount: NumberPresenter,
  suggestionSizeSum: NumberPresenter,
  durationQuantile: DurationPresenter,
};

// Returns the field key that holds the title for the given __typename,
// falling back to `title` when the type doesn't declare an alias.
export const titleFieldFor = (typename) => {
  return presentersByObjectType[typename]?.titleField ?? 'title';
};

// The title-aliased field hands the whole item to the type-routed presenter;
// other field keys resolve to that field's value.
export const dataForField = (item, fieldKey) => {
  // eslint-disable-next-line no-underscore-dangle
  if (!fieldKey || fieldKey === titleFieldFor(item?.__typename)) return item;
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

// Resolves a presenter for the given (item, fieldKey, variant) by walking the
// dispatch chain: null → field-key → typename → primitive.
export const presenterFor = (item, fieldKey, variant) => {
  const field = dataForField(item, fieldKey);
  if (field == null) return NullPresenter;
  return (
    presenterByFieldKey(fieldKey, item, variant) ||
    presenterByObjectType(field, variant) ||
    presenterByPrimitiveType(field)
  );
};

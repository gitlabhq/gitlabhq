<script>
import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import StatusPresenter from 'ee_else_ce/glql/components/presenters/status.vue';
import HealthPresenter from 'ee_else_ce/glql/components/presenters/health.vue';

import IssuablePresenter from './issuable.vue';
import MilestonePresenter from './milestone.vue';
import UserPresenter from './user.vue';
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

const presentersByObjectType = {
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
  Project: LinkPresenter,
  Pipeline: CiItemPresenter,
  CiJob: CiItemPresenter,
  CiStage: NamedTextPresenter,
  Group: LinkPresenter,
};

// Maps field keys to presenters. Values can be:
// - A presenter component (used for all parent types)
// - An object mapping parent __typename to a presenter (type-scoped),
//   with an optional `default` key as fallback for unmatched types
const presentersByFieldKey = {
  health: HealthPresenter,
  healthStatus: HealthPresenter,
  state: StatePresenter,
  status: { Pipeline: CiStatusPresenter, CiJob: CiStatusPresenter },
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
};

export default {
  name: 'FieldPresenter',
  props: {
    item: {
      required: true,
      type: Object,
    },
    fieldKey: {
      required: false,
      type: String,
      default: '',
    },
  },
  methods: {
    dataForField(item, fieldKey) {
      return fieldKey === 'title' || !fieldKey ? item : item[fieldKey];
    },
    nullPresenter(field) {
      return field == null ? NullPresenter : null;
    },
    presenterByObjectType(field) {
      // eslint-disable-next-line no-underscore-dangle
      return presentersByObjectType[field?.__typename];
    },
    presenterByFieldKey(fieldKey) {
      const byKey = presentersByFieldKey[fieldKey];
      if (!byKey) return null;
      if (byKey.name) return byKey;
      // eslint-disable-next-line no-underscore-dangle
      return byKey[this.item?.__typename] || byKey.default;
    },
    presenterByPrimitiveType(field) {
      if (typeof field === 'boolean') return BoolPresenter;
      if (Array.isArray(field?.nodes)) return CollectionPresenter;
      if (typeof field === 'object') return LinkPresenter;
      if (typeof field === 'string' && field.match(/^\d{4}-\d{2}-\d{2}/)) return TimePresenter;
      return TextPresenter;
    },
    componentForField(item, fieldKey) {
      const field = this.dataForField(item, fieldKey);
      return (
        this.nullPresenter(field) ||
        this.presenterByObjectType(field) ||
        this.presenterByFieldKey(fieldKey) ||
        this.presenterByPrimitiveType(field)
      );
    },
  },
};
</script>
<template>
  <component
    :is="componentForField(item, fieldKey)"
    :item="item"
    :field-key="fieldKey"
    :data="dataForField(item, fieldKey)"
  />
</template>

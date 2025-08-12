<script>
import IssuablePresenter from './issuable.vue';
import MilestonePresenter from './milestone.vue';
import UserPresenter from './user.vue';
import LabelPresenter from './label.vue';
import IterationPresenter from './iteration.vue';
import StatusPresenter from './status.vue';
import TypePresenter from './type.vue';
import DimensionPresenter from './dimension.vue';
import HealthPresenter from './health.vue';
import StatePresenter from './state.vue';
import HtmlPresenter from './html.vue';
import CodePresenter from './code.vue';
import NullPresenter from './null.vue';
import BoolPresenter from './bool.vue';
import CollectionPresenter from './collection.vue';
import LinkPresenter from './link.vue';
import TimePresenter from './time.vue';
import TextPresenter from './text.vue';

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

  GlqlDimension: DimensionPresenter,
};

const presentersByFieldKey = {
  health: HealthPresenter,
  healthStatus: HealthPresenter,
  state: StatePresenter,
  description: HtmlPresenter,
  descriptionHtml: HtmlPresenter,
  lastComment: HtmlPresenter,
  sourceBranch: CodePresenter,
  targetBranch: CodePresenter,
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
    componentForField(item, fieldKey) {
      const field = this.dataForField(item, fieldKey);

      if (typeof field === 'undefined' || field === null) return NullPresenter;

      const presenter =
        // eslint-disable-next-line no-underscore-dangle
        presentersByObjectType[field.__typename] || presentersByFieldKey[fieldKey];
      if (presenter) return presenter;

      if (typeof field === 'boolean') return BoolPresenter;
      if (typeof field === 'object')
        return Array.isArray(field.nodes) ? CollectionPresenter : LinkPresenter;

      if (typeof field === 'string' && field.match(/^\d{4}-\d{2}-\d{2}/) /* date YYYY-MM-DD */)
        return TimePresenter;

      return TextPresenter;
    },
    dataForField(item, fieldKey) {
      return fieldKey === 'title' || !fieldKey ? item : item[fieldKey];
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

<script>
import { defineAsyncComponent } from 'vue';
import { GlLabel, GlTruncate } from '@gitlab/ui';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { isScopedLabel } from '~/lib/utils/common_utils';
import IssueAssignees from '~/issuable/components/issue_assignees.vue';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import {
  findAssigneesWidget,
  findHealthStatusWidget,
  findIterationWidget,
  findLabelsWidget,
  findMilestoneWidget,
  findStartAndDueDateWidget,
  findStatusWidget,
  findWeightWidget,
  getDisplayReference,
} from '~/work_items/utils';
import {
  COLUMN_ASSIGNEES,
  COLUMN_CREATED_AT,
  COLUMN_DUE_DATE,
  COLUMN_HEALTH_STATUS,
  COLUMN_ITERATION,
  COLUMN_LABELS,
  COLUMN_MILESTONE,
  COLUMN_REFERENCE,
  COLUMN_START_DATE,
  COLUMN_STATUS,
  COLUMN_WEIGHT,
} from '../constants';

const MAX_VISIBLE_ASSIGNEES = 3;

export default {
  name: 'WorkItemTableCell',
  components: {
    GlLabel,
    GlTruncate,
    IssueAssignees,
    IssuableMilestone,
    IssueHealthStatus: defineAsyncComponent(
      () => import('ee_component/issues/components/issue_health_status.vue'),
    ),
    IssueIteration: defineAsyncComponent(
      () => import('ee_component/boards/components/issue_iteration.vue'),
    ),
    WorkItemStatusBadge: defineAsyncComponent(
      () => import('ee_component/work_items/components/shared/work_item_status_badge.vue'),
    ),
  },
  inject: {
    hasScopedLabelsFeature: {
      default: false,
    },
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    columnKey: {
      type: String,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    // An item from the table's own namespace shows as `#iid`. An item from somewhere else
    // (e.g. another project on a group's table) keeps its full reference.
    reference() {
      return getDisplayReference(this.rootPageFullPath, this.item.reference);
    },
    status() {
      return findStatusWidget(this.item)?.status;
    },
    assignees() {
      return findAssigneesWidget(this.item)?.assignees?.nodes ?? [];
    },
    singleAssigneeName() {
      return this.assignees.length === 1 ? this.assignees[0].name : null;
    },
    labels() {
      return findLabelsWidget(this.item)?.labels?.nodes ?? [];
    },
    allowsScopedLabels() {
      return Boolean(
        this.hasScopedLabelsFeature || findLabelsWidget(this.item)?.allowsScopedLabels,
      );
    },
    weight() {
      return findWeightWidget(this.item)?.weight;
    },
    milestone() {
      return findMilestoneWidget(this.item)?.milestone;
    },
    iteration() {
      return findIterationWidget(this.item)?.iteration;
    },
    startDate() {
      return findStartAndDueDateWidget(this.item)?.startDate;
    },
    dueDate() {
      return findStartAndDueDateWidget(this.item)?.dueDate;
    },
    healthStatus() {
      return findHealthStatusWidget(this.item)?.healthStatus;
    },
  },
  methods: {
    formatDate(date) {
      return localeDateFormat.asDate.format(newDate(date));
    },
    showAsScopedLabel(label) {
      return this.allowsScopedLabels && isScopedLabel(label);
    },
  },
  COLUMN_ASSIGNEES,
  COLUMN_CREATED_AT,
  COLUMN_DUE_DATE,
  COLUMN_HEALTH_STATUS,
  COLUMN_ITERATION,
  COLUMN_LABELS,
  COLUMN_MILESTONE,
  COLUMN_REFERENCE,
  COLUMN_START_DATE,
  COLUMN_STATUS,
  COLUMN_WEIGHT,
  MAX_VISIBLE_ASSIGNEES,
};
</script>

<template>
  <span v-if="columnKey === $options.COLUMN_REFERENCE" data-testid="cell-reference">
    <gl-truncate :text="reference" position="middle" />
  </span>

  <work-item-status-badge
    v-else-if="columnKey === $options.COLUMN_STATUS && status"
    data-testid="cell-status"
    :item="status"
  />

  <div
    v-else-if="columnKey === $options.COLUMN_ASSIGNEES && assignees.length"
    class="gl-flex gl-items-center gl-gap-2"
    data-testid="cell-assignees"
  >
    <issue-assignees
      :assignees="assignees"
      :icon-size="16"
      :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
      class="gl-flex gl-shrink-0 gl-items-center"
    />
    <gl-truncate v-if="singleAssigneeName" :text="singleAssigneeName" />
  </div>

  <div
    v-else-if="columnKey === $options.COLUMN_LABELS && labels.length"
    class="gl-flex gl-flex-nowrap gl-gap-2 gl-overflow-hidden"
    data-testid="cell-labels"
  >
    <gl-label
      v-for="label in labels"
      :key="label.id"
      :background-color="label.color"
      :title="label.title"
      :description="label.description"
      :scoped="showAsScopedLabel(label)"
    />
  </div>

  <span
    v-else-if="columnKey === $options.COLUMN_WEIGHT && weight != null"
    data-testid="cell-weight"
  >
    {{ weight }}
  </span>

  <issuable-milestone
    v-else-if="columnKey === $options.COLUMN_MILESTONE && milestone"
    data-testid="cell-milestone"
    :milestone="milestone"
  />

  <issue-iteration
    v-else-if="columnKey === $options.COLUMN_ITERATION && iteration"
    data-testid="cell-iteration"
    :iteration="iteration"
  />

  <time
    v-else-if="columnKey === $options.COLUMN_START_DATE && startDate"
    :datetime="startDate"
    data-testid="cell-start-date"
  >
    {{ formatDate(startDate) }}
  </time>

  <time
    v-else-if="columnKey === $options.COLUMN_DUE_DATE && dueDate"
    :datetime="dueDate"
    data-testid="cell-due-date"
  >
    {{ formatDate(dueDate) }}
  </time>

  <issue-health-status
    v-else-if="columnKey === $options.COLUMN_HEALTH_STATUS && healthStatus"
    data-testid="cell-health-status"
    display-as-text
    text-size="sm"
    :health-status="healthStatus"
  />

  <time
    v-else-if="columnKey === $options.COLUMN_CREATED_AT && item.createdAt"
    :datetime="item.createdAt"
    data-testid="cell-created-at"
  >
    {{ formatDate(item.createdAt) }}
  </time>
</template>

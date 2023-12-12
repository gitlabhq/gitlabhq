<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  sprintfWorkItem,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_WEIGHT,
  WORK_ITEM_TYPE_VALUE_KEY_RESULT,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
} from '../constants';
import WorkItemDueDate from './work_item_due_date.vue';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemMilestone from './work_item_milestone.vue';
import WorkItemParentInline from './work_item_parent_inline.vue';
import WorkItemParent from './work_item_parent_with_edit.vue';

export default {
  components: {
    WorkItemLabels,
    WorkItemMilestone,
    WorkItemAssignees,
    WorkItemDueDate,
    WorkItemParent,
    WorkItemParentInline,
    WorkItemWeightInline: () =>
      import('ee_component/work_items/components/work_item_weight_inline.vue'),
    WorkItemWeight: () =>
      import('ee_component/work_items/components/work_item_weight_with_edit.vue'),
    WorkItemProgress: () => import('ee_component/work_items/components/work_item_progress.vue'),
    WorkItemIteration: () => import('ee_component/work_items/components/work_item_iteration.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status_with_edit.vue'),
    WorkItemHealthStatusInline: () =>
      import('ee_component/work_items/components/work_item_health_status_inline.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItem: {
      type: Object,
      required: true,
    },
    workItemParentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem?.userPermissions?.deleteWorkItem;
    },
    canSetWorkItemMetadata() {
      return this.workItem?.userPermissions?.setWorkItemMetadata;
    },
    canAssignUnassignUser() {
      return this.workItemAssignees && this.canSetWorkItemMetadata;
    },
    confidentialTooltip() {
      return sprintfWorkItem(this.$options.i18n.confidentialTooltip, this.workItemType);
    },
    workItemAssignees() {
      return this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES);
    },
    workItemLabels() {
      return this.isWidgetPresent(WIDGET_TYPE_LABELS);
    },
    workItemDueDate() {
      return this.isWidgetPresent(WIDGET_TYPE_START_AND_DUE_DATE);
    },
    workItemWeight() {
      return this.isWidgetPresent(WIDGET_TYPE_WEIGHT);
    },
    workItemProgress() {
      return this.isWidgetPresent(WIDGET_TYPE_PROGRESS);
    },
    workItemIteration() {
      return this.isWidgetPresent(WIDGET_TYPE_ITERATION);
    },
    workItemHealthStatus() {
      return this.isWidgetPresent(WIDGET_TYPE_HEALTH_STATUS);
    },
    workItemHierarchy() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY);
    },
    workItemMilestone() {
      return this.isWidgetPresent(WIDGET_TYPE_MILESTONE);
    },
    showWorkItemParent() {
      return (
        this.workItemType === WORK_ITEM_TYPE_VALUE_OBJECTIVE ||
        this.workItemType === WORK_ITEM_TYPE_VALUE_KEY_RESULT ||
        this.workItemType === WORK_ITEM_TYPE_VALUE_TASK
      );
    },
    workItemParent() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
  },
  methods: {
    isWidgetPresent(type) {
      return this.workItem?.widgets?.find((widget) => widget.type === type);
    },
  },
};
</script>

<template>
  <div class="work-item-attributes-wrapper">
    <work-item-assignees
      v-if="workItemAssignees"
      :can-update="canUpdate"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :assignees="workItemAssignees.assignees.nodes"
      :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
      :work-item-type="workItemType"
      :can-invite-members="workItemAssignees.canInviteMembers"
      @error="$emit('error', $event)"
    />
    <work-item-labels
      v-if="workItemLabels"
      :can-update="canUpdate"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      @error="$emit('error', $event)"
    />
    <work-item-due-date
      v-if="workItemDueDate"
      :can-update="canUpdate"
      :due-date="workItemDueDate.dueDate"
      :start-date="workItemDueDate.startDate"
      :work-item-id="workItem.id"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
    />
    <work-item-milestone
      v-if="workItemMilestone"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-milestone="workItemMilestone.milestone"
      :work-item-type="workItemType"
      :can-update="canUpdate"
      @error="$emit('error', $event)"
    />
    <template v-if="workItemWeight">
      <work-item-weight
        v-if="glFeatures.workItemsMvc2"
        class="gl-mb-5"
        :can-update="canUpdate"
        :weight="workItemWeight.weight"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
      <work-item-weight-inline
        v-else
        class="gl-mb-5"
        :can-update="canUpdate"
        :weight="workItemWeight.weight"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <work-item-progress
      v-if="workItemProgress"
      class="gl-mb-5"
      :can-update="canUpdate"
      :progress="workItemProgress.progress"
      :work-item-id="workItem.id"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
    />
    <work-item-iteration
      v-if="workItemIteration"
      class="gl-mb-5"
      :full-path="fullPath"
      :iteration="workItemIteration.iteration"
      :can-update="canUpdate"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
    />
    <template v-if="workItemHealthStatus">
      <work-item-health-status
        v-if="glFeatures.workItemsMvc2"
        class="gl-mb-5"
        :health-status="workItemHealthStatus.healthStatus"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
      <work-item-health-status-inline
        v-else
        class="gl-mb-5"
        :health-status="workItemHealthStatus.healthStatus"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="showWorkItemParent">
      <work-item-parent
        v-if="glFeatures.workItemsMvc2"
        class="gl-mb-5"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-type="workItemType"
        :parent="workItemParent"
        @error="$emit('error', $event)"
      />
      <work-item-parent-inline
        v-else
        class="gl-mb-5"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-type="workItemType"
        :parent="workItemParent"
        @error="$emit('error', $event)"
      />
    </template>
  </div>
</template>

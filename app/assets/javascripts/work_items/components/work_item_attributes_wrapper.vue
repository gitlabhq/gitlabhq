<script>
import Participants from '~/sidebar/components/participants/participants.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_PARTICIPANTS,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_TIME_TRACKING,
  WIDGET_TYPE_ROLLEDUP_DATES,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_COLOR,
  WORK_ITEM_TYPE_VALUE_EPIC,
} from '../constants';
import WorkItemAssigneesWithEdit from './work_item_assignees_with_edit.vue';
import WorkItemDueDateWithEdit from './work_item_due_date_with_edit.vue';
import WorkItemLabelsWithEdit from './work_item_labels_with_edit.vue';
import WorkItemMilestoneWithEdit from './work_item_milestone_with_edit.vue';
import WorkItemParent from './work_item_parent_with_edit.vue';
import WorkItemTimeTracking from './work_item_time_tracking.vue';

export default {
  components: {
    Participants,
    WorkItemLabelsWithEdit,
    WorkItemMilestoneWithEdit,
    WorkItemAssigneesWithEdit,
    WorkItemDueDateWithEdit,
    WorkItemParent,
    WorkItemTimeTracking,
    WorkItemWeight: () =>
      import('ee_component/work_items/components/work_item_weight_with_edit.vue'),
    WorkItemProgressWithEdit: () =>
      import('ee_component/work_items/components/work_item_progress_with_edit.vue'),
    WorkItemIteration: () =>
      import('ee_component/work_items/components/work_item_iteration_with_edit.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status_with_edit.vue'),
    WorkItemColorWithEdit: () =>
      import('ee_component/work_items/components/work_item_color_with_edit.vue'),
    WorkItemRolledupDates: () =>
      import('ee_component/work_items/components/work_item_rolledup_dates.vue'),
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
    workItemAssignees() {
      return this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES);
    },
    workItemLabels() {
      return this.isWidgetPresent(WIDGET_TYPE_LABELS);
    },
    workItemDueDate() {
      return this.isWidgetPresent(WIDGET_TYPE_START_AND_DUE_DATE);
    },
    workItemRolledupDates() {
      return this.isWidgetPresent(WIDGET_TYPE_ROLLEDUP_DATES);
    },
    workItemWeight() {
      return this.isWidgetPresent(WIDGET_TYPE_WEIGHT);
    },
    workItemParticipants() {
      return this.isWidgetPresent(WIDGET_TYPE_PARTICIPANTS);
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
    showRolledupDates() {
      return (
        this.glFeatures.workItemsRolledupDates && this.workItemType === WORK_ITEM_TYPE_VALUE_EPIC
      );
    },
    workItemParent() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    workItemTimeTracking() {
      return this.isWidgetPresent(WIDGET_TYPE_TIME_TRACKING);
    },
    workItemColor() {
      return this.isWidgetPresent(WIDGET_TYPE_COLOR);
    },
    workItemParticipantNodes() {
      return this.workItemParticipants?.participants?.nodes ?? [];
    },
    workItemAuthor() {
      return this.workItem?.author;
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
    <template v-if="workItemAssignees">
      <work-item-assignees-with-edit
        class="gl-mb-5 js-assignee"
        :can-update="canUpdate"
        :full-path="fullPath"
        :work-item-id="workItem.id"
        :assignees="workItemAssignees.assignees.nodes"
        :participants="workItemParticipantNodes"
        :work-item-author="workItemAuthor"
        :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
        :work-item-type="workItemType"
        :can-invite-members="workItemAssignees.canInviteMembers"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemLabels">
      <work-item-labels-with-edit
        class="gl-mb-5 js-labels"
        :can-update="canUpdate"
        :full-path="fullPath"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemWeight">
      <work-item-weight
        class="gl-mb-5"
        :can-update="canUpdate"
        :weight="workItemWeight.weight"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemRolledupDates && showRolledupDates">
      <work-item-rolledup-dates
        :can-update="canUpdate"
        :due-date-is-fixed="workItemRolledupDates.dueDateIsFixed"
        :due-date-fixed="workItemRolledupDates.dueDateFixed"
        :due-date-inherited="workItemRolledupDates.dueDate"
        :start-date-is-fixed="workItemRolledupDates.startDateIsFixed"
        :start-date-fixed="workItemRolledupDates.startDateFixed"
        :start-date-inherited="workItemRolledupDates.startDate"
        :work-item-type="workItemType"
        :work-item="workItem"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemMilestone">
      <work-item-milestone-with-edit
        class="gl-mb-5 js-milestone"
        :full-path="fullPath"
        :work-item-id="workItem.id"
        :work-item-milestone="workItemMilestone.milestone"
        :work-item-type="workItemType"
        :can-update="canUpdate"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemIteration">
      <work-item-iteration
        class="gl-mb-5"
        :full-path="fullPath"
        :iteration="workItemIteration.iteration"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemDueDate && !showRolledupDates">
      <work-item-due-date-with-edit
        :can-update="canUpdate"
        :due-date="workItemDueDate.dueDate"
        :start-date="workItemDueDate.startDate"
        :work-item-type="workItemType"
        :work-item="workItem"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemProgress">
      <work-item-progress-with-edit
        class="gl-mb-5"
        :can-update="canUpdate"
        :progress="workItemProgress.progress"
        :work-item-id="workItem.id"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemHealthStatus">
      <work-item-health-status
        class="gl-mb-5"
        :health-status="workItemHealthStatus.healthStatus"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-iid="workItem.iid"
        :work-item-type="workItemType"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemColor">
      <work-item-color-with-edit
        class="gl-mb-5"
        :work-item="workItem"
        :can-update="canUpdate"
        @error="$emit('error', $event)"
      />
    </template>
    <template v-if="workItemHierarchy">
      <work-item-parent
        class="gl-mb-5 gl-pt-5 gl-border-t gl-border-gray-50"
        :can-update="canUpdate"
        :work-item-id="workItem.id"
        :work-item-type="workItemType"
        :parent="workItemParent"
        @error="$emit('error', $event)"
      />
    </template>
    <work-item-time-tracking
      v-if="workItemTimeTracking"
      class="gl-mb-5 gl-pt-5 gl-border-t gl-border-gray-50"
      :time-estimate="workItemTimeTracking.timeEstimate"
      :total-time-spent="workItemTimeTracking.totalTimeSpent"
    />
    <participants
      v-if="workItemParticipants"
      class="gl-mb-5 gl-pt-5 gl-border-t gl-border-gray-50"
      :number-of-less-participants="10"
      :participants="workItemParticipants.participants.nodes"
    />
  </div>
</template>

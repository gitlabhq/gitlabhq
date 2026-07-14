<script>
import Participants from '~/sidebar/components/participants/participants.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ListType } from '~/boards/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import WorkItemDates from 'ee_else_ce/work_items/components/work_item_dates.vue';

import { WORK_ITEM_TYPE_NAME_EPIC, STATE_CLOSED } from '../constants';
import {
  findAssigneesWidget,
  findColorWidget,
  findCrmContactsWidget,
  findCustomFieldsWidget,
  findHealthStatusWidget,
  findHierarchyWidget,
  findHierarchyWidgetDefinition,
  findIterationWidget,
  findLabelsWidget,
  findMilestoneWidget,
  findParticipantsWidget,
  findProgressWidget,
  findStartAndDueDateWidget,
  findStatusWidget,
  findTimeTrackingWidget,
  findWeightWidget,
} from '../utils';
import workItemParticipantsQuery from '../graphql/work_item_participants.query.graphql';
import workItemAllowedParentTypesQuery from '../graphql/work_item_allowed_parent_types.query.graphql';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemMilestone from './work_item_milestone.vue';
import WorkItemParent from './work_item_parent.vue';
import WorkItemTimeTracking from './work_item_time_tracking.vue';
import WorkItemCrmContacts from './work_item_crm_contacts.vue';

export default {
  name: 'WorkItemAttributesWrapper',
  ListType,
  components: {
    Participants,
    WorkItemLabels,
    WorkItemMilestone,
    WorkItemAssignees,
    WorkItemParent,
    WorkItemTimeTracking,
    WorkItemCrmContacts,
    WorkItemDates,
    WorkItemWeight: () => import('ee_component/work_items/components/work_item_weight.vue'),
    WorkItemProgress: () => import('ee_component/work_items/components/work_item_progress.vue'),
    WorkItemIteration: () => import('ee_component/work_items/components/work_item_iteration.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status.vue'),
    WorkItemColor: () => import('ee_component/work_items/components/work_item_color.vue'),
    WorkItemCustomFields: () =>
      import('ee_component/work_items/components/work_item_custom_fields.vue'),
    WorkItemStatus: () => import('ee_component/work_items/components/work_item_status.vue'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    hasSubepicsFeature: {
      default: false,
    },
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItem: {
      type: Object,
      required: true,
    },
    groupPath: {
      type: String,
      required: false,
      default: '',
    },
    isGroup: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['attributesUpdated', 'error'],
  data() {
    return {
      workItemParticipants: {},
      allowedParentTypes: [],
    };
  },
  apollo: {
    workItemParticipants: {
      query: workItemParticipantsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItem.iid,
          useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
        };
      },
      skip() {
        return !this.workItem.iid;
      },
      update({ namespace }) {
        if (!namespace?.workItem) return {};

        return findParticipantsWidget(namespace.workItem)?.participants || {};
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
    allowedParentTypes: {
      query: workItemAllowedParentTypesQuery,
      variables() {
        return {
          id: this.workItem.id,
        };
      },
      update(data) {
        return findHierarchyWidgetDefinition(data.workItem)?.allowedParentTypes?.nodes ?? [];
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
  },
  computed: {
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    canUpdateMetadata() {
      return this.workItem?.userPermissions?.setWorkItemMetadata;
    },
    canAdminWorkItemLink() {
      return this.workItem?.userPermissions?.adminWorkItemLink;
    },
    canUpdateParent() {
      return this.canUpdateMetadata || this.canAdminWorkItemLink;
    },
    workItemParticipantNodes() {
      return this.workItemParticipants.nodes || [];
    },
    workItemParticipantCount() {
      return this.workItemParticipants.count || 0;
    },
    workItemAssignees() {
      return findAssigneesWidget(this.workItem);
    },
    workItemLabels() {
      return findLabelsWidget(this.workItem);
    },
    workItemStatus() {
      return findStatusWidget(this.workItem);
    },
    workItemStartAndDueDate() {
      return findStartAndDueDateWidget(this.workItem);
    },
    canWorkItemRollUp() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    workItemWeight() {
      return findWeightWidget(this.workItem);
    },
    workItemProgress() {
      return findProgressWidget(this.workItem);
    },
    workItemIteration() {
      return findIterationWidget(this.workItem);
    },
    workItemHealthStatus() {
      return findHealthStatusWidget(this.workItem);
    },
    workItemHierarchy() {
      return findHierarchyWidget(this.workItem);
    },
    workItemMilestone() {
      return findMilestoneWidget(this.workItem);
    },
    isParentEnabled() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC ? this.hasSubepicsFeature : true;
    },
    workItemParent() {
      return findHierarchyWidget(this.workItem)?.parent;
    },
    showParent() {
      return this.allowedParentTypes.length > 0 && this.workItemHierarchy && this.isParentEnabled;
    },
    workItemTimeTracking() {
      return findTimeTrackingWidget(this.workItem);
    },
    workItemColor() {
      return findColorWidget(this.workItem);
    },
    hasParent() {
      return this.workItemHierarchy?.hasParent;
    },
    isWorkItemClosed() {
      return this.workItem.state === STATE_CLOSED;
    },
    workItemCrmContacts() {
      const crmContactsWidget = findCrmContactsWidget(this.workItem);
      return crmContactsWidget && crmContactsWidget.contactsAvailable ? crmContactsWidget : null;
    },
    customFields() {
      return findCustomFieldsWidget(this.workItem)?.customFieldValues;
    },
  },
};
</script>

<template>
  <div class="work-item-attributes-wrapper work-item-sidebar-container">
    <work-item-status
      v-if="workItemStatus"
      class="work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      :full-path="fullPath"
      @error="$emit('error', $event)"
      @statusUpdated="$emit('attributesUpdated', { type: $options.ListType.status, ids: [$event] })"
    />
    <work-item-assignees
      v-if="workItemAssignees"
      class="js-assignee work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :full-path="fullPath"
      :is-group="isGroup"
      :work-item-id="workItem.id"
      :assignees="workItemAssignees.assignees.nodes"
      :participants="workItemParticipantNodes"
      :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
      :work-item-type="workItemType"
      :can-invite-members="workItemAssignees.canInviteMembers"
      @error="$emit('error', $event)"
      @assigneesUpdated="
        $emit('attributesUpdated', { type: $options.ListType.assignee, ids: $event })
      "
    />
    <work-item-labels
      v-if="workItemLabels"
      class="js-labels work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :full-path="fullPath"
      :is-group="isGroup"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
      @labelsUpdated="$emit('attributesUpdated', { type: $options.ListType.label, ids: $event })"
    />
    <work-item-parent
      v-if="showParent"
      class="work-item-attributes-item"
      :can-update="canUpdateParent"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-type="workItemType"
      :parent="workItemParent"
      :has-parent="hasParent"
      :group-path="groupPath"
      @error="$emit('error', $event)"
    />
    <work-item-weight
      v-if="workItemWeight"
      class="work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :widget="workItemWeight"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
    />
    <work-item-milestone
      v-if="workItemMilestone"
      class="js-milestone work-item-attributes-item"
      :is-group="isGroup"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-milestone="workItemMilestone.milestone"
      :work-item-type="workItemType"
      :can-update="canUpdateMetadata"
      @error="$emit('error', $event)"
      @milestoneUpdated="
        $emit('attributesUpdated', { type: $options.ListType.milestone, ids: [$event] })
      "
    />
    <work-item-iteration
      v-if="workItemIteration"
      class="work-item-attributes-item"
      :full-path="fullPath"
      :is-group="isGroup"
      :iteration="workItemIteration.iteration"
      :can-update="canUpdateMetadata"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
      @iterationUpdated="
        $emit('attributesUpdated', { type: $options.ListType.iteration, ids: [$event] })
      "
    />
    <work-item-dates
      v-if="workItemStartAndDueDate"
      class="work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :start-date="workItemStartAndDueDate.startDate"
      :due-date="workItemStartAndDueDate.dueDate"
      :is-fixed="workItemStartAndDueDate.isFixed"
      :should-roll-up="canWorkItemRollUp"
      :work-item-type="workItemType"
      :work-item="workItem"
      @error="$emit('error', $event)"
    />
    <work-item-progress
      v-if="workItemProgress"
      class="work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :progress="workItemProgress.progress"
      :work-item-id="workItem.id"
      :work-item-type="workItemType"
      @error="$emit('error', $event)"
    />
    <work-item-health-status
      v-if="workItemHealthStatus"
      class="work-item-attributes-item"
      :is-work-item-closed="isWorkItemClosed"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
      :full-path="fullPath"
      @error="$emit('error', $event)"
    />
    <work-item-color
      v-if="workItemColor"
      class="work-item-attributes-item"
      :work-item="workItem"
      :can-update="canUpdateMetadata"
      @error="$emit('error', $event)"
    />
    <work-item-custom-fields
      v-if="customFields"
      :work-item-id="workItem.id"
      :work-item-type="workItemType"
      :custom-fields="customFields"
      :can-update="canUpdateMetadata"
      @error="$emit('error', $event)"
    />
    <work-item-time-tracking
      v-if="workItemTimeTracking"
      class="work-item-attributes-item"
      :can-update="canUpdateMetadata"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
    />
    <work-item-crm-contacts
      v-if="workItemCrmContacts"
      class="gl-border-t gl-mb-5 gl-border-subtle gl-pt-5"
      :full-path="fullPath"
      :work-item-id="workItem.id"
      :work-item-iid="workItem.iid"
      :work-item-type="workItemType"
    />
    <participants
      v-if="workItemParticipantNodes.length"
      class="work-item-attributes-item"
      data-testid="work-item-participants"
      :participants="workItemParticipantNodes"
      :participant-count="workItemParticipantCount"
    />
  </div>
</template>

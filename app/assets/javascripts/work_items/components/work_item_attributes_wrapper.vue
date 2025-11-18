<script>
import { GlBanner, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import Participants from '~/sidebar/components/participants/participants.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { ListType } from '~/boards/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

import WorkItemDates from 'ee_else_ce/work_items/components/work_item_dates.vue';

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
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_COLOR,
  WIDGET_TYPE_CRM_CONTACTS,
  WORK_ITEM_TYPE_NAME_EPIC,
  NAME_TO_ENUM_MAP,
  WIDGET_TYPE_CUSTOM_FIELDS,
  WIDGET_TYPE_STATUS,
  STATE_CLOSED,
} from '../constants';
import { findHierarchyWidgetDefinition } from '../utils';
import workItemParticipantsQuery from '../graphql/work_item_participants.query.graphql';
import workItemAllowedParentTypesQuery from '../graphql/work_item_allowed_parent_types.query.graphql';

import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemMilestone from './work_item_milestone.vue';
import WorkItemParent from './work_item_parent.vue';
import WorkItemTimeTracking from './work_item_time_tracking.vue';
import WorkItemCrmContacts from './work_item_crm_contacts.vue';

export default {
  ListType,
  components: {
    GlBanner,
    GlLink,
    UserCalloutDismisser,
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
    newTrialPath: {
      default: '',
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
        };
      },
      skip() {
        return !this.workItem.iid;
      },
      update({ workspace }) {
        if (!workspace?.workItem) return {};

        const workItemParticipantData = this.isWidgetPresent(
          WIDGET_TYPE_PARTICIPANTS,
          workspace.workItem,
        );

        return workItemParticipantData?.participants || {};
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
        return (
          findHierarchyWidgetDefinition(data.workItem)?.allowedParentTypes?.nodes.map(
            (el) => NAME_TO_ENUM_MAP[el.name],
          ) || []
        );
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
      return this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES);
    },
    workItemLabels() {
      return this.isWidgetPresent(WIDGET_TYPE_LABELS);
    },
    workItemStatus() {
      return this.isWidgetPresent(WIDGET_TYPE_STATUS);
    },
    workItemStartAndDueDate() {
      return this.isWidgetPresent(WIDGET_TYPE_START_AND_DUE_DATE);
    },
    canWorkItemRollUp() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
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
    isParentEnabled() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC ? this.hasSubepicsFeature : true;
    },
    workItemParent() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    showParent() {
      return this.allowedParentTypes.length > 0 && this.workItemHierarchy && this.isParentEnabled;
    },
    workItemTimeTracking() {
      return this.isWidgetPresent(WIDGET_TYPE_TIME_TRACKING);
    },
    workItemColor() {
      return this.isWidgetPresent(WIDGET_TYPE_COLOR);
    },
    hasParent() {
      return this.workItemHierarchy?.hasParent;
    },
    isWorkItemClosed() {
      return this.workItem.state === STATE_CLOSED;
    },
    workItemCrmContacts() {
      const crmContactsWidget = this.isWidgetPresent(WIDGET_TYPE_CRM_CONTACTS);
      return crmContactsWidget && crmContactsWidget.contactsAvailable ? crmContactsWidget : null;
    },
    customFields() {
      return this.isWidgetPresent(WIDGET_TYPE_CUSTOM_FIELDS)?.customFieldValues;
    },
  },
  methods: {
    isWidgetPresent(type, workItem = this.workItem) {
      return workItem?.widgets?.find((widget) => widget.type === type);
    },
  },
  promoUrl: PROMO_URL,
  i18n: {
    upgradeBanner: {
      title: s__('Promotions|Upgrade for advanced agile planning'),
      description: s__(
        'Promotions|Unlock epics, advanced boards, status, weight, iterations, and more to seamlessly tie your strategy to your DevSecOps workflows with GitLab.',
      ),
      primaryAction: s__('Promotions|Try it for free'),
      secondaryAction: s__('Promotions|Learn more'),
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
      :is-group="isGroup"
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
      :time-estimate="workItemTimeTracking.timeEstimate"
      :timelogs="workItemTimeTracking.timelogs.nodes"
      :total-time-spent="workItemTimeTracking.totalTimeSpent"
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
    <user-callout-dismisser
      v-if="workItem.showPlanUpgradePromotion && newTrialPath"
      feature-name="ultimate_trial"
    >
      <template #default="{ dismiss, shouldShowCallout }">
        <gl-banner
          v-if="shouldShowCallout"
          class="work-item-attributes-item gl-mt-6"
          :title="$options.i18n.upgradeBanner.title"
          :button-text="$options.i18n.upgradeBanner.primaryAction"
          :button-link="newTrialPath"
          @close="dismiss"
        >
          <p>{{ $options.i18n.upgradeBanner.description }}</p>
          <template #actions>
            <gl-link
              class="gl-ml-4"
              :href="`${$options.promoUrl}/features/?stage=plan`"
              target="_blank"
            >
              {{ $options.i18n.upgradeBanner.secondaryAction }}
            </gl-link>
          </template>
        </gl-banner>
      </template>
    </user-callout-dismisser>
  </div>
</template>

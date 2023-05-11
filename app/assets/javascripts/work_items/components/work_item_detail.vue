<script>
import { isEmpty } from 'lodash';
import { produce } from 'immer';
import {
  GlAlert,
  GlSkeletonLoader,
  GlLoadingIcon,
  GlIcon,
  GlBadge,
  GlButton,
  GlTooltipDirective,
  GlEmptyState,
} from '@gitlab/ui';
import noAccessSvg from '@gitlab/svgs/dist/illustrations/analytics/no-access.svg';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { getParameterByName, updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_WORK_ITEM } from '~/graphql_shared/constants';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import {
  sprintfWorkItem,
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_NOTIFICATIONS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_PROGRESS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_HEALTH_STATUS,
  WORK_ITEM_TYPE_VALUE_ISSUE,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WIDGET_TYPE_NOTES,
} from '../constants';

import workItemDatesSubscription from '../../graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '../graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '../graphql/work_item_assignees.subscription.graphql';
import workItemMilestoneSubscription from '../graphql/work_item_milestone.subscription.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '../graphql/update_work_item_task.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { findHierarchyWidgetChildren } from '../utils';

import WorkItemTree from './work_item_links/work_item_tree.vue';
import WorkItemActions from './work_item_actions.vue';
import WorkItemState from './work_item_state.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemCreatedUpdated from './work_item_created_updated.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemDueDate from './work_item_due_date.vue';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemMilestone from './work_item_milestone.vue';
import WorkItemNotes from './work_item_notes.vue';
import WorkItemDetailModal from './work_item_detail_modal.vue';

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlSkeletonLoader,
    GlIcon,
    GlEmptyState,
    WorkItemAssignees,
    WorkItemActions,
    WorkItemCreatedUpdated,
    WorkItemDescription,
    WorkItemDueDate,
    WorkItemLabels,
    WorkItemTitle,
    WorkItemState,
    WorkItemWeight: () => import('ee_component/work_items/components/work_item_weight.vue'),
    WorkItemProgress: () => import('ee_component/work_items/components/work_item_progress.vue'),
    WorkItemTypeIcon,
    WorkItemIteration: () => import('ee_component/work_items/components/work_item_iteration.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status.vue'),
    WorkItemMilestone,
    WorkItemTree,
    WorkItemNotes,
    WorkItemDetailModal,
    AbuseCategorySelector,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath', 'reportAbusePath'],
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    workItemParentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    const workItemId = getParameterByName('work_item_id');

    return {
      error: undefined,
      updateError: undefined,
      workItem: {},
      updateInProgress: false,
      modalWorkItemId: isPositiveInteger(workItemId)
        ? convertToGraphQLId(TYPENAME_WORK_ITEM, workItemId)
        : null,
      modalWorkItemIid: getParameterByName('work_item_iid'),
      isReportDrawerOpen: false,
      reportedUrl: '',
      reportedUserId: 0,
    };
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data.workspace.workItems.nodes[0] ?? {};
      },
      error() {
        this.setEmptyState();
      },
      result(res) {
        // need to handle this when the res is loading: true, netWorkStatus: 1, partial: true
        if (!res.data) {
          return;
        }
        if (isEmpty(this.workItem)) {
          this.setEmptyState();
        }
        if (!this.isModal && this.workItem.project) {
          const path = this.workItem.project?.fullPath
            ? ` · ${this.workItem.project.fullPath}`
            : '';

          document.title = `${this.workItem.title} · ${this.workItem?.workItemType?.name}${path}`;
        }
      },
      subscribeToMore: [
        {
          document: workItemTitleSubscription,
          variables() {
            return {
              issuableId: this.workItem.id,
            };
          },
          skip() {
            return !this.workItem?.id;
          },
        },
        {
          document: workItemDatesSubscription,
          variables() {
            return {
              issuableId: this.workItem.id,
            };
          },
          skip() {
            return !this.isWidgetPresent(WIDGET_TYPE_START_AND_DUE_DATE) || !this.workItem?.id;
          },
        },
        {
          document: workItemAssigneesSubscription,
          variables() {
            return {
              issuableId: this.workItem.id,
            };
          },
          skip() {
            return !this.isWidgetPresent(WIDGET_TYPE_ASSIGNEES) || !this.workItem?.id;
          },
        },
        {
          document: workItemMilestoneSubscription,
          variables() {
            return {
              issuableId: this.workItem.id,
            };
          },
          skip() {
            return !this.isWidgetPresent(WIDGET_TYPE_MILESTONE) || !this.workItem?.id;
          },
        },
      ],
    },
  },
  computed: {
    workItemLoading() {
      return isEmpty(this.workItem) && this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    workItemTypeId() {
      return this.workItem.workItemType?.id;
    },
    workItemBreadcrumbReference() {
      return this.workItemType ? `${this.workItemType} #${this.workItem.iid}` : '';
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
    fullPath() {
      return this.workItem?.project.fullPath;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    parentWorkItem() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY)?.parent;
    },
    parentWorkItemType() {
      return this.parentWorkItem?.workItemType?.name;
    },
    parentWorkItemIconName() {
      return this.parentWorkItem?.workItemType?.iconName;
    },
    parentWorkItemConfidentiality() {
      return this.parentWorkItem?.confidential;
    },
    parentWorkItemReference() {
      return this.parentWorkItem ? `${this.parentWorkItem.title} #${this.parentWorkItem.iid}` : '';
    },
    parentUrl() {
      // Once more types are moved to have Work Items involved
      // we need to handle this properly.
      if (this.parentWorkItemType === WORK_ITEM_TYPE_VALUE_ISSUE) {
        return `../../issues/${this.parentWorkItem?.iid}`;
      }
      return this.parentWorkItem?.webUrl;
    },
    workItemIconName() {
      return this.workItem?.workItemType?.iconName;
    },
    noAccessSvgPath() {
      return `data:image/svg+xml;utf8,${encodeURIComponent(noAccessSvg)}`;
    },
    hasDescriptionWidget() {
      return this.isWidgetPresent(WIDGET_TYPE_DESCRIPTION);
    },
    workItemNotificationsSubscribed() {
      return Boolean(this.isWidgetPresent(WIDGET_TYPE_NOTIFICATIONS)?.subscribed);
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
    workItemHierarchy() {
      return this.isWidgetPresent(WIDGET_TYPE_HIERARCHY);
    },
    workItemIteration() {
      return this.isWidgetPresent(WIDGET_TYPE_ITERATION);
    },
    workItemHealthStatus() {
      return this.isWidgetPresent(WIDGET_TYPE_HEALTH_STATUS);
    },
    workItemMilestone() {
      return this.isWidgetPresent(WIDGET_TYPE_MILESTONE);
    },
    workItemNotes() {
      return this.isWidgetPresent(WIDGET_TYPE_NOTES);
    },
    children() {
      return this.workItem ? findHierarchyWidgetChildren(this.workItem) : [];
    },
    workItemBodyClass() {
      return {
        'gl-pt-5': !this.updateError && !this.isModal,
      };
    },
  },
  mounted() {
    if (this.modalWorkItemId || this.modalWorkItemIid) {
      this.openInModal({
        event: undefined,
        modalWorkItem: { id: this.modalWorkItemId, iid: this.modalWorkItemIid },
      });
    }
  },
  methods: {
    isWidgetPresent(type) {
      return this.workItem?.widgets?.find((widget) => widget.type === type);
    },
    toggleConfidentiality(confidentialStatus) {
      this.updateInProgress = true;
      let updateMutation = updateWorkItemMutation;
      let inputVariables = {
        id: this.workItem.id,
        confidential: confidentialStatus,
      };

      if (this.parentWorkItem) {
        updateMutation = updateWorkItemTaskMutation;
        inputVariables = {
          id: this.parentWorkItem.id,
          taskData: {
            id: this.workItem.id,
            confidential: confidentialStatus,
          },
        };
      }

      this.$apollo
        .mutate({
          mutation: updateMutation,
          variables: {
            input: inputVariables,
          },
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors, workItem, task },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }

            this.$emit('workItemUpdated', {
              confidential: workItem?.confidential || task?.confidential,
            });
          },
        )
        .catch((error) => {
          this.updateError = error.message;
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
    setEmptyState() {
      this.error = this.$options.i18n.fetchError;
      document.title = s__('404|Not found');
    },
    addChild(child) {
      const { defaultClient: client } = this.$apollo.provider.clients;
      this.toggleChildFromCache(child, child.id, client);
    },
    toggleChildFromCache(workItem, childId, store) {
      const query = {
        query: workItemByIidQuery,
        variables: { fullPath: this.fullPath, iid: this.workItemIid },
      };

      const sourceData = store.readQuery(query);

      const newData = produce(sourceData, (draftState) => {
        const { widgets } = draftState.workspace.workItems.nodes[0];
        const widgetHierarchy = widgets.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);

        const index = widgetHierarchy.children.nodes.findIndex((child) => child.id === childId);

        if (index >= 0) {
          widgetHierarchy.children.nodes.splice(index, 1);
        } else {
          widgetHierarchy.children.nodes.push(workItem);
        }
      });

      store.writeQuery({ ...query, data: newData });
    },
    async updateWorkItem(workItem, childId, parentId) {
      return this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: { input: { id: childId, hierarchyWidget: { parentId } } },
        update: (store) => this.toggleChildFromCache(workItem, childId, store),
      });
    },
    async undoChildRemoval(workItem, childId) {
      try {
        const { data } = await this.updateWorkItem(workItem, childId, this.workItem.id);

        if (data.workItemUpdate.errors.length === 0) {
          this.activeToast?.hide();
        }
      } catch (error) {
        this.updateError = s__('WorkItem|Something went wrong while undoing child removal.');
        Sentry.captureException(error);
      } finally {
        this.activeToast?.hide();
      }
    },
    async removeChild({ id }) {
      try {
        const { data } = await this.updateWorkItem(null, id, null);

        if (data.workItemUpdate.errors.length === 0) {
          this.activeToast = this.$toast.show(s__('WorkItem|Child removed'), {
            action: {
              text: s__('WorkItem|Undo'),
              onClick: this.undoChildRemoval.bind(this, data.workItemUpdate.workItem, id),
            },
          });
        }
      } catch (error) {
        this.updateError = s__('WorkItem|Something went wrong while removing child.');
        Sentry.captureException(error);
      }
    },
    updateHasNotes() {
      this.$emit('has-notes');
    },
    updateUrl(modalWorkItem) {
      updateHistory({
        url: setUrlParams({ work_item_iid: modalWorkItem?.iid }),
        replace: true,
      });
    },
    openInModal({ event, modalWorkItem }) {
      if (!this.workItemsMvc2Enabled) {
        return;
      }

      if (event) {
        event.preventDefault();

        this.updateUrl(modalWorkItem);
      }

      if (this.isModal) {
        this.$emit('update-modal', event, modalWorkItem);
        return;
      }
      this.modalWorkItemId = modalWorkItem.id;
      this.modalWorkItemIid = modalWorkItem.iid;
      this.$refs.modal.show();
    },
    openReportAbuseDrawer(reply) {
      if (this.isModal) {
        this.$emit('openReportAbuse', reply);
      } else {
        this.toggleReportAbuseDrawer(true, reply);
      }
    },
    toggleReportAbuseDrawer(isOpen, reply = {}) {
      this.isReportDrawerOpen = isOpen;
      this.reportedUrl = reply.url || {};
      this.reportedUserId = reply.author ? getIdFromGraphQLId(reply.author.id) : 0;
    },
  },

  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
};
</script>

<template>
  <section>
    <section v-if="updateError" class="flash-container flash-container-page sticky">
      <gl-alert class="gl-mb-3" variant="danger" @dismiss="updateError = undefined">
        {{ updateError }}
      </gl-alert>
    </section>
    <section :class="workItemBodyClass">
      <div v-if="workItemLoading" class="gl-max-w-26 gl-py-5">
        <gl-skeleton-loader :height="65" :width="240">
          <rect width="240" height="20" x="5" y="0" rx="4" />
          <rect width="100" height="20" x="5" y="45" rx="4" />
        </gl-skeleton-loader>
      </div>
      <template v-else>
        <div class="gl-display-flex gl-align-items-center" data-testid="work-item-body">
          <ul
            v-if="parentWorkItem"
            class="list-unstyled gl-display-flex gl-mr-auto gl-max-w-26 gl-md-max-w-50p gl-min-w-0 gl-mb-0 gl-z-index-0"
            data-testid="work-item-parent"
          >
            <li class="gl-ml-n4 gl-display-flex gl-align-items-center gl-overflow-hidden">
              <gl-button
                v-gl-tooltip.hover
                class="gl-text-truncate gl-max-w-full"
                :icon="parentWorkItemIconName"
                category="tertiary"
                :href="parentUrl"
                :title="parentWorkItemReference"
                @click="openInModal({ event: $event, modalWorkItem: parentWorkItem })"
                >{{ parentWorkItemReference }}</gl-button
              >
              <gl-icon name="chevron-right" :size="16" class="gl-flex-shrink-0" />
            </li>
            <li
              class="gl-px-4 gl-py-3 gl-line-height-0 gl-display-flex gl-align-items-center gl-overflow-hidden gl-flex-shrink-0"
            >
              <work-item-type-icon
                :work-item-icon-name="workItemIconName"
                :work-item-type="workItemType && workItemType.toUpperCase()"
              />
              {{ workItemBreadcrumbReference }}
            </li>
          </ul>
          <div
            v-else-if="!error && !workItemLoading"
            class="gl-mr-auto"
            data-testid="work-item-type"
          >
            <work-item-type-icon
              :work-item-icon-name="workItemIconName"
              :work-item-type="workItemType && workItemType.toUpperCase()"
            />
            {{ workItemBreadcrumbReference }}
          </div>
          <gl-loading-icon v-if="updateInProgress" :inline="true" class="gl-mr-3" />
          <gl-badge
            v-if="workItem.confidential"
            v-gl-tooltip.bottom
            :title="confidentialTooltip"
            variant="warning"
            icon="eye-slash"
            class="gl-mr-3 gl-cursor-help"
            >{{ __('Confidential') }}</gl-badge
          >
          <work-item-actions
            v-if="canUpdate || canDelete"
            :work-item-id="workItem.id"
            :subscribed-to-notifications="workItemNotificationsSubscribed"
            :work-item-type="workItemType"
            :work-item-type-id="workItemTypeId"
            :can-delete="canDelete"
            :can-update="canUpdate"
            :is-confidential="workItem.confidential"
            :is-parent-confidential="parentWorkItemConfidentiality"
            @deleteWorkItem="$emit('deleteWorkItem', { workItemType, workItemId: workItem.id })"
            @toggleWorkItemConfidentiality="toggleConfidentiality"
            @error="updateError = $event"
          />
          <gl-button
            v-if="isModal"
            category="tertiary"
            data-testid="work-item-close"
            icon="close"
            :aria-label="__('Close')"
            @click="$emit('close')"
          />
        </div>
        <work-item-title
          v-if="workItem.title"
          :work-item-id="workItem.id"
          :work-item-title="workItem.title"
          :work-item-type="workItemType"
          :work-item-parent-id="workItemParentId"
          :can-update="canUpdate"
          @error="updateError = $event"
        />
        <work-item-created-updated :work-item-iid="workItemIid" />
        <work-item-state
          :work-item="workItem"
          :work-item-parent-id="workItemParentId"
          :can-update="canUpdate"
          @error="updateError = $event"
        />
        <work-item-assignees
          v-if="workItemAssignees"
          :can-update="canUpdate"
          :work-item-id="workItem.id"
          :assignees="workItemAssignees.assignees.nodes"
          :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
          :work-item-type="workItemType"
          :can-invite-members="workItemAssignees.canInviteMembers"
          @error="updateError = $event"
        />
        <work-item-labels
          v-if="workItemLabels"
          :can-update="canUpdate"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          @error="updateError = $event"
        />
        <work-item-due-date
          v-if="workItemDueDate"
          :can-update="canUpdate"
          :due-date="workItemDueDate.dueDate"
          :start-date="workItemDueDate.startDate"
          :work-item-id="workItem.id"
          :work-item-type="workItemType"
          @error="updateError = $event"
        />
        <work-item-milestone
          v-if="workItemMilestone"
          :work-item-id="workItem.id"
          :work-item-milestone="workItemMilestone.milestone"
          :work-item-type="workItemType"
          :can-update="canUpdate"
          @error="updateError = $event"
        />
        <work-item-weight
          v-if="workItemWeight"
          class="gl-mb-5"
          :can-update="canUpdate"
          :weight="workItemWeight.weight"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          :work-item-type="workItemType"
          @error="updateError = $event"
        />
        <work-item-progress
          v-if="workItemProgress"
          class="gl-mb-5"
          :can-update="canUpdate"
          :progress="workItemProgress.progress"
          :work-item-id="workItem.id"
          :work-item-type="workItemType"
          @error="updateError = $event"
        />
        <work-item-iteration
          v-if="workItemIteration"
          class="gl-mb-5"
          :iteration="workItemIteration.iteration"
          :can-update="canUpdate"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          :work-item-type="workItemType"
          @error="updateError = $event"
        />
        <work-item-health-status
          v-if="workItemHealthStatus"
          class="gl-mb-5"
          :health-status="workItemHealthStatus.healthStatus"
          :can-update="canUpdate"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          :work-item-type="workItemType"
          @error="updateError = $event"
        />
        <work-item-description
          v-if="hasDescriptionWidget"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          class="gl-pt-5"
          @error="updateError = $event"
        />
        <work-item-tree
          v-if="workItemType === $options.WORK_ITEM_TYPE_VALUE_OBJECTIVE"
          :work-item-type="workItemType"
          :parent-work-item-type="workItem.workItemType.name"
          :work-item-id="workItem.id"
          :work-item-iid="workItemIid"
          :children="children"
          :can-update="canUpdate"
          :confidential="workItem.confidential"
          @addWorkItemChild="addChild"
          @removeChild="removeChild"
          @show-modal="openInModal"
        />
        <work-item-notes
          v-if="workItemNotes"
          :work-item-id="workItem.id"
          :work-item-iid="workItem.iid"
          :work-item-type="workItemType"
          :is-modal="isModal"
          :assignees="workItemAssignees && workItemAssignees.assignees.nodes"
          :can-set-work-item-metadata="canAssignUnassignUser"
          :report-abuse-path="reportAbusePath"
          class="gl-pt-5"
          @error="updateError = $event"
          @has-notes="updateHasNotes"
          @openReportAbuse="openReportAbuseDrawer"
        />
        <gl-empty-state
          v-if="error"
          :title="$options.i18n.fetchErrorTitle"
          :description="error"
          :svg-path="noAccessSvgPath"
        />
      </template>
      <work-item-detail-modal
        v-if="!isModal"
        ref="modal"
        :work-item-id="modalWorkItemId"
        :work-item-iid="modalWorkItemIid"
        :show="true"
        @close="updateUrl"
        @openReportAbuse="toggleReportAbuseDrawer(true, $event)"
      />
      <abuse-category-selector
        v-if="isReportDrawerOpen"
        :reported-user-id="reportedUserId"
        :reported-from-url="reportedUrl"
        :show-drawer="true"
        @close-drawer="toggleReportAbuseDrawer(false)"
      />
    </section>
  </section>
</template>

<script>
import { camelCase, chunk } from 'lodash';
import { GlForm } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  BULK_EDIT_NO_VALUE,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_HIERARCHY,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_STATUS,
} from '../../constants';
import workItemBulkUpdateMutation from '../../graphql/list/work_item_bulk_update.mutation.graphql';
import getAvailableBulkEditWidgets from '../../graphql/list/get_available_bulk_edit_widgets.query.graphql';
import WorkItemBulkEditAssignee from './work_item_bulk_edit_assignee.vue';
import WorkItemBulkEditDropdown from './work_item_bulk_edit_dropdown.vue';
import WorkItemBulkEditLabels from './work_item_bulk_edit_labels.vue';
import WorkItemBulkEditMilestone from './work_item_bulk_edit_milestone.vue';
import WorkItemBulkEditParent from './work_item_bulk_edit_parent.vue';
import WorkItemBulkMove from './work_item_bulk_move.vue';

const WorkItemBulkEditIteration = () =>
  import('ee_component/work_items/components/list/work_item_bulk_edit_iteration.vue');
const WorkItemBulkEditStatus = () =>
  import('ee_component/work_items/components/work_item_bulk_edit/work_item_bulk_edit_status.vue');

const BULK_EDIT_CHUNK_SIZE = 25;

export default {
  name: 'WorkItemBulkEditSidebar',
  confidentialityItems: [
    { text: __('Confidential'), value: 'true' },
    { text: __('Not confidential'), value: 'false' },
  ],
  healthStatusItems: [
    { text: __('On track'), value: 'on_track' },
    { text: __('Needs attention'), value: 'needs_attention' },
    { text: __('At risk'), value: 'at_risk' },
  ],
  stateItems: [
    { text: __('Open'), value: 'reopen' },
    { text: __('Closed'), value: 'close' },
  ],
  subscriptionItems: [
    { text: __('Subscribe'), value: 'subscribe' },
    { text: __('Unsubscribe'), value: 'unsubscribe' },
  ],
  components: {
    GlForm,
    WorkItemBulkEditAssignee,
    WorkItemBulkEditDropdown,
    WorkItemBulkEditLabels,
    WorkItemBulkEditIteration,
    WorkItemBulkEditStatus,
    WorkItemBulkEditMilestone,
    WorkItemBulkEditParent,
    WorkItemBulkMove,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['hasIssuableHealthStatusFeature', 'hasIterationsFeature', 'hasStatusFeature'],
  props: {
    checkedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    fullPath: {
      type: String,
      required: true,
    },
    isEpicsList: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      availableWidgets: [],
      addLabelIds: [],
      assigneeId: undefined,
      confidentiality: undefined,
      healthStatus: undefined,
      removeLabelIds: [],
      state: undefined,
      statusId: undefined,
      subscription: undefined,
      iterationId: undefined,
      milestoneId: undefined,
      parentId: undefined,
    };
  },
  apollo: {
    availableWidgets: {
      query: getAvailableBulkEditWidgets,
      variables() {
        return {
          fullPath: this.fullPath,
          ids: this.workItemTypeIds,
        };
      },
      update(data) {
        return data.namespace?.workItemsWidgets || [];
      },
      skip() {
        return this.checkedItems.length === 0;
      },
    },
  },
  computed: {
    hasAttributeValuesSelected() {
      return [
        this.addLabelIds.length > 0,
        this.removeLabelIds.length > 0,
        this.assigneeId !== undefined,
        this.confidentiality !== undefined,
        this.healthStatus !== undefined,
        this.state !== undefined,
        this.statusId !== undefined,
        this.subscription !== undefined,
        this.iterationId !== undefined,
        this.milestoneId !== undefined,
        this.parentId !== undefined,
      ].includes(true);
    },
    showStatusDropdown() {
      return this.hasStatusFeature && !this.isEpicsList;
    },
    workItemTypeIds() {
      return [...new Set(this.checkedItems.map((item) => item.workItemType.id))];
    },
    hasItemsSelected() {
      return this.checkedItems.length > 0;
    },
    canEditAssignees() {
      return this.availableWidgets.includes(WIDGET_TYPE_ASSIGNEES);
    },
    canEditLabels() {
      return this.availableWidgets.includes(WIDGET_TYPE_LABELS);
    },
    canEditHealthStatus() {
      return this.availableWidgets.includes(WIDGET_TYPE_HEALTH_STATUS);
    },
    canEditIteration() {
      return this.availableWidgets.includes(WIDGET_TYPE_ITERATION);
    },
    canEditStatus() {
      return this.availableWidgets.includes(WIDGET_TYPE_STATUS);
    },
    canEditMilestone() {
      return this.availableWidgets.includes(WIDGET_TYPE_MILESTONE);
    },
    canEditParent() {
      return this.availableWidgets.includes(WIDGET_TYPE_HIERARCHY);
    },
    shouldDisableMove() {
      return !this.hasItemsSelected || this.hasAttributeValuesSelected;
    },
  },
  methods: {
    async handleFormSubmitted() {
      this.$emit('start');

      try {
        await this.performBulkEdit();
        this.$emit('success', { refetchCounts: Boolean(this.state) });
      } catch (error) {
        createAlert({
          message: s__('WorkItem|Something went wrong while bulk editing.'),
          captureError: true,
          error,
        });
      } finally {
        this.$emit('finish');
      }
    },
    async performBulkEdit() {
      const input = this.createBulkEditInput();
      return this.chunkedBulkEditMutation(input);
    },

    createBulkEditInput() {
      let assigneeIds;
      if (this.assigneeId === BULK_EDIT_NO_VALUE) {
        assigneeIds = [null];
      } else if (this.assigneeId) {
        assigneeIds = [this.assigneeId];
      }

      const hasLabelsToUpdate = this.addLabelIds.length > 0 || this.removeLabelIds.length > 0;

      return {
        fullPath: this.fullPath,
        labelsWidget: hasLabelsToUpdate
          ? {
              addLabelIds: this.addLabelIds,
              removeLabelIds: this.removeLabelIds,
            }
          : undefined,
        assigneesWidget: assigneeIds
          ? {
              assigneeIds,
            }
          : undefined,
        confidential: this.confidentiality ? this.confidentiality === 'true' : undefined,
        healthStatusWidget: this.formatValue({
          name: 'healthStatus',
          value: this.healthStatus,
        }),
        iterationWidget: this.formatValue({ name: 'iterationId', value: this.iterationId }),
        milestoneWidget: this.formatValue({ name: 'milestoneId', value: this.milestoneId }),
        statusWidget: this.formatValue({ name: 'status', value: this.statusId }),
        stateEvent: this.state && this.state.toUpperCase(),
        subscriptionEvent: this.subscription && this.subscription.toUpperCase(),
        hierarchyWidget: this.formatValue({ name: 'parentId', value: this.parentId }),
      };
    },
    async chunkedBulkEditMutation(input) {
      const chunkedItems = chunk(this.checkedItems, BULK_EDIT_CHUNK_SIZE);

      const mutations = chunkedItems.map((itemsChunk) => this.bulkEditMutation(input, itemsChunk));

      const results = await Promise.allSettled(mutations);

      const failedChunks = results.filter((result) => result.status === 'rejected');
      if (failedChunks.length > 0) {
        const messages = failedChunks.map((failure) => failure.reason);
        throw new Error(
          `${failedChunks.length} out of ${results.length} chunk(s) failed to update`,
          { cause: messages },
        );
      }

      return results;
    },
    bulkEditMutation(input, items) {
      return this.$apollo.mutate({
        mutation: workItemBulkUpdateMutation,
        variables: {
          input: {
            ...input,
            ids: items.map((item) => item.id),
          },
        },
      });
    },
    formatValue({ name, value }) {
      if (!value) {
        return undefined;
      }
      if (value === BULK_EDIT_NO_VALUE) {
        return { [name]: null };
      }
      if (name === 'healthStatus') {
        return { [name]: camelCase(value) };
      }
      return { [name]: value };
    },
    handleMoveSuccess({ toastMessage }) {
      this.$emit('success', { refetchCounts: true, toastMessage });
    },
  },
};
</script>

<template>
  <gl-form
    id="work-item-list-bulk-edit"
    class="gl-px-4 gl-py-5"
    @submit.prevent="handleFormSubmitted"
  >
    <work-item-bulk-edit-dropdown
      v-if="!isEpicsList"
      v-model="state"
      :header-text="__('Select state')"
      :items="$options.stateItems"
      :label="__('State')"
      :disabled="!hasItemsSelected"
      data-testid="bulk-edit-state"
    />
    <work-item-bulk-edit-status
      v-if="showStatusDropdown"
      v-model="statusId"
      :full-path="fullPath"
      :checked-items="checkedItems"
      :disabled="!hasItemsSelected || !canEditStatus"
    />
    <work-item-bulk-edit-assignee
      v-model="assigneeId"
      :full-path="fullPath"
      :is-group="isGroup"
      :disabled="!hasItemsSelected || !canEditAssignees"
    />
    <work-item-bulk-edit-labels
      :form-label="__('Add labels')"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="addLabelIds"
      :disabled="!hasItemsSelected || !canEditLabels"
      data-testid="bulk-edit-add-labels"
      @select="addLabelIds = $event"
    />
    <work-item-bulk-edit-labels
      :checked-items="checkedItems"
      :form-label="__('Remove labels')"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="removeLabelIds"
      :disabled="!hasItemsSelected || !canEditLabels"
      data-testid="bulk-edit-remove-labels"
      @select="removeLabelIds = $event"
    />
    <work-item-bulk-edit-dropdown
      v-if="hasIssuableHealthStatusFeature"
      v-model="healthStatus"
      :header-text="__('Select health status')"
      :items="$options.healthStatusItems"
      :label="__('Health status')"
      :no-value-text="s__('WorkItem|No health status')"
      :disabled="!hasItemsSelected || !canEditHealthStatus"
      data-testid="bulk-edit-health-status"
    />
    <work-item-bulk-edit-dropdown
      v-model="subscription"
      :header-text="__('Select subscription')"
      :items="$options.subscriptionItems"
      :label="__('Subscription')"
      :disabled="!hasItemsSelected"
      data-testid="bulk-edit-subscription"
    />
    <work-item-bulk-edit-dropdown
      v-model="confidentiality"
      :header-text="__('Select confidentiality')"
      :items="$options.confidentialityItems"
      :label="__('Confidentiality')"
      :disabled="!hasItemsSelected"
      data-testid="bulk-edit-confidentiality"
    />
    <work-item-bulk-edit-iteration
      v-if="!isEpicsList && hasIterationsFeature"
      v-model="iterationId"
      :full-path="fullPath"
      :is-group="isGroup"
      :disabled="!hasItemsSelected || !canEditIteration"
    />
    <work-item-bulk-edit-milestone
      v-model="milestoneId"
      :full-path="fullPath"
      :is-group="isGroup"
      :disabled="!hasItemsSelected || !canEditMilestone"
    />
    <work-item-bulk-edit-parent
      v-model="parentId"
      :full-path="fullPath"
      :is-group="isGroup"
      :disabled="!hasItemsSelected || !canEditParent"
      :selected-work-item-types-ids="workItemTypeIds"
      data-testid="bulk-edit-parent"
    />
    <template v-if="!isEpicsList">
      <hr />
      <work-item-bulk-move
        :checked-items="checkedItems"
        :full-path="fullPath"
        :disabled="shouldDisableMove"
        @moveStart="$emit('start')"
        @moveSuccess="handleMoveSuccess"
        @moveFinish="$emit('finish')"
      />
    </template>
  </gl-form>
</template>

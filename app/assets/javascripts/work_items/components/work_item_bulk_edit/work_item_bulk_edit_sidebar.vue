<script>
import { GlForm } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import { BULK_UPDATE_UNASSIGNED } from '../../constants';
import workItemBulkUpdateMutation from '../../graphql/list/work_item_bulk_update.mutation.graphql';
import workItemParent from '../../graphql/list/work_item_parent.query.graphql';
import WorkItemBulkEditAssignee from './work_item_bulk_edit_assignee.vue';
import WorkItemBulkEditDropdown from './work_item_bulk_edit_dropdown.vue';
import WorkItemBulkEditLabels from './work_item_bulk_edit_labels.vue';

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
  },
  inject: ['hasIssuableHealthStatusFeature'],
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
      addLabelIds: [],
      assigneeId: undefined,
      confidentiality: undefined,
      healthStatus: undefined,
      parentId: undefined,
      removeLabelIds: [],
      state: undefined,
      subscription: undefined,
    };
  },
  apollo: {
    parentId: {
      query: workItemParent,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.namespace.id;
      },
      skip() {
        return !this.isEpicsList;
      },
    },
  },
  computed: {
    legacyBulkEditEndpoint() {
      const domain = gon.relative_url_root || '';
      const basePath = this.isGroup ? `groups/${this.fullPath}` : this.fullPath;
      return `${domain}/${basePath}/-/issues/bulk_update`;
    },
  },
  methods: {
    async handleFormSubmitted() {
      this.$emit('start');

      const executeBulkEdit = this.isEpicsList ? this.performBulkEdit : this.performLegacyBulkEdit;

      try {
        await executeBulkEdit();
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
    performBulkEdit() {
      return this.$apollo.mutate({
        mutation: workItemBulkUpdateMutation,
        variables: {
          input: {
            parentId: this.parentId,
            ids: this.checkedItems.map((item) => item.id),
            labelsWidget: {
              addLabelIds: this.addLabelIds,
              removeLabelIds: this.removeLabelIds,
            },
          },
        },
      });
    },
    performLegacyBulkEdit() {
      let assigneeIds;
      if (this.assigneeId === BULK_UPDATE_UNASSIGNED) {
        assigneeIds = [0];
      } else if (this.assigneeId) {
        assigneeIds = [getIdFromGraphQLId(this.assigneeId)];
      }

      const update = {
        add_label_ids: this.addLabelIds.map(getIdFromGraphQLId),
        assignee_ids: assigneeIds,
        confidential: this.confidentiality,
        health_status: this.healthStatus,
        issuable_ids: this.checkedItems.map((item) => getIdFromGraphQLId(item.id)).join(','),
        remove_label_ids: this.removeLabelIds.map(getIdFromGraphQLId),
        state_event: this.state,
        subscription_event: this.subscription,
      };

      return axios.post(this.legacyBulkEditEndpoint, { update });
    },
  },
};
</script>

<template>
  <gl-form id="work-item-list-bulk-edit" class="gl-p-5" @submit.prevent="handleFormSubmitted">
    <work-item-bulk-edit-dropdown
      v-if="!isEpicsList"
      v-model="state"
      :header-text="__('Select state')"
      :items="$options.stateItems"
      :label="__('State')"
      data-testid="bulk-edit-state"
    />
    <work-item-bulk-edit-assignee
      v-if="!isEpicsList"
      v-model="assigneeId"
      :full-path="fullPath"
      :is-group="isGroup"
    />
    <work-item-bulk-edit-labels
      :form-label="__('Add labels')"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="addLabelIds"
      @select="addLabelIds = $event"
    />
    <work-item-bulk-edit-labels
      :checked-items="checkedItems"
      :form-label="__('Remove labels')"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="removeLabelIds"
      @select="removeLabelIds = $event"
    />
    <work-item-bulk-edit-dropdown
      v-if="!isEpicsList && hasIssuableHealthStatusFeature"
      v-model="healthStatus"
      :header-text="__('Select health status')"
      :items="$options.healthStatusItems"
      :label="__('Health status')"
      data-testid="bulk-edit-health-status"
    />
    <work-item-bulk-edit-dropdown
      v-if="!isEpicsList"
      v-model="subscription"
      :header-text="__('Select subscription')"
      :items="$options.subscriptionItems"
      :label="__('Subscription')"
      data-testid="bulk-edit-subscription"
    />
    <work-item-bulk-edit-dropdown
      v-if="!isEpicsList"
      v-model="confidentiality"
      :header-text="__('Select confidentiality')"
      :items="$options.confidentialityItems"
      :label="__('Confidentiality')"
      data-testid="bulk-edit-confidentiality"
    />
  </gl-form>
</template>

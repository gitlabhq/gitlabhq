<script>
import { GlIcon, GlAlert, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { s__, __ } from '~/locale';
import { findWidget } from '~/issues/list/utils';

import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDevelopmentQuery from '~/work_items/graphql/work_item_development.query.graphql';
import workItemDevelopmentUpdatedSubscription from '~/work_items/graphql/work_item_development.subscription.graphql';
import {
  sprintfWorkItem,
  WIDGET_TYPE_DEVELOPMENT,
  STATE_OPEN,
  DEVELOPMENT_ITEMS_ANCHOR,
} from '~/work_items/constants';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemActionsSplitButton from '~/work_items/components/work_item_links/work_item_actions_split_button.vue';
import WorkItemDevelopmentRelationshipList from './work_item_development_relationship_list.vue';
import WorkItemCreateBranchMergeRequestModal from './work_item_create_branch_merge_request_modal.vue';

export default {
  components: {
    GlIcon,
    GlAlert,
    WorkItemDevelopmentRelationshipList,
    CrudComponent,
    WorkItemActionsSplitButton,
    WorkItemCreateBranchMergeRequestModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItemFullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      error: undefined,
      workItem: {},
      workItemDevelopment: {},
      showCreateBranchAndMrModal: false,
      showBranchFlow: true,
      showMergeRequestFlow: false,
      showCreateOptions: true,
    };
  },
  computed: {
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    workItemState() {
      return this.workItem?.state;
    },
    workItemTypeName() {
      return this.workItem?.workItemType?.name;
    },
    isLoading() {
      return (
        this.$apollo.queries.workItem.loading || this.$apollo.queries.workItemDevelopment.loading
      );
    },
    willAutoCloseByMergeRequest() {
      return this.workItemDevelopment?.willAutoCloseByMergeRequest;
    },
    relatedMergeRequests() {
      return this.workItemDevelopment?.relatedMergeRequests?.nodes || [];
    },
    closingMergeRequests() {
      return this.workItemDevelopment?.closingMergeRequests?.nodes || [];
    },
    featureFlags() {
      return this.workItemDevelopment?.featureFlags?.nodes || [];
    },
    relatedBranches() {
      return this.workItemDevelopment?.relatedBranches?.nodes || [];
    },
    shouldShowDevWidget() {
      return this.error || !this.isRelatedDevelopmentListEmpty;
    },
    isRelatedDevelopmentListEmpty() {
      return (
        this.relatedMergeRequests.length === 0 &&
        this.closingMergeRequests.length === 0 &&
        this.featureFlags.length === 0 &&
        this.relatedBranches.length === 0
      );
    },
    showAutoCloseInformation() {
      return (
        this.closingMergeRequests.length > 0 && this.willAutoCloseByMergeRequest && !this.isLoading
      );
    },
    openStateText() {
      return this.closingMergeRequests.length > 1
        ? sprintfWorkItem(
            s__(
              'WorkItem|This %{workItemType} will be closed when any of the following is merged.',
            ),
            this.workItemTypeName,
          )
        : sprintfWorkItem(
            s__('WorkItem|This %{workItemType} will be closed when the following is merged.'),
            this.workItemTypeName,
          );
    },
    closedStateText() {
      return sprintfWorkItem(
        s__('WorkItem|The %{workItemType} was closed automatically when a branch was merged.'),
        this.workItemTypeName,
      );
    },
    tooltipText() {
      return this.workItemState === STATE_OPEN ? this.openStateText : this.closedStateText;
    },
    showAddButton() {
      return this.canUpdate && this.showCreateOptions;
    },
    isConfidentialWorkItem() {
      return this.workItem?.confidential;
    },
    projectId() {
      return this.workItem?.project?.id;
    },
    addItemsActions() {
      return [
        {
          name: __('Merge request'),
          items: [
            {
              text: __('Create merge request'),
              action: this.openModal.bind(this, false, true),
              extraAttrs: {
                'data-testid': 'create-mr-dropdown-button',
              },
            },
          ],
        },
        {
          name: __('Branch'),
          items: [
            {
              text: __('Create branch'),
              action: this.openModal.bind(this, true, false),
              extraAttrs: {
                'data-testid': 'create-branch-dropdown-button',
              },
            },
          ],
        },
      ];
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItem || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(error) {
        this.error = s__(
          'WorkItem|Something went wrong when fetching items. Please refresh this page.',
        );
        Sentry.captureException(error);
      },
    },
    workItemDevelopment: {
      query: workItemDevelopmentQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      update(data) {
        return findWidget(WIDGET_TYPE_DEVELOPMENT, data?.workItem) || {};
      },
      skip() {
        return !this.workItemIid;
      },
      error(error) {
        this.error = s__(
          "WorkItem|One or more items cannot be shown. If you're using SAML authentication, this could mean your session has expired.",
        );
        Sentry.captureException(error);
      },
      subscribeToMore: {
        document: workItemDevelopmentUpdatedSubscription,
        variables() {
          return {
            id: this.workItem.id,
          };
        },
        skip() {
          return !this.workItem?.id;
        },
      },
    },
  },
  methods: {
    openModal(createBranch = true, createMergeRequest = false) {
      this.toggleCreateModal(true);
      this.showBranchFlow = createBranch;
      this.showMergeRequestFlow = createMergeRequest;
    },
    toggleCreateModal(showOrhide) {
      this.showCreateBranchAndMrModal = showOrhide;
    },
    updatePermissions(canCreateBranch) {
      this.showCreateOptions = canCreateBranch;
    },
  },
  DEVELOPMENT_ITEMS_ANCHOR,
};
</script>

<template>
  <div>
    <crud-component
      v-if="shouldShowDevWidget"
      ref="workItemDevelopment"
      :title="s__('WorkItem|Development')"
      :anchor-id="$options.DEVELOPMENT_ITEMS_ANCHOR"
      :is-loading="isLoading"
      is-collapsible
      persist-collapsed-state
      data-testid="work-item-development"
    >
      <template #count>
        <span
          v-if="showAutoCloseInformation"
          v-gl-tooltip
          tabindex="0"
          class="!gl-p-0 hover:!gl-bg-transparent"
          :title="tooltipText"
          :aria-label="tooltipText"
          data-testid="more-information"
        >
          <gl-icon name="information-o" variant="info" />
        </span>
      </template>

      <template #actions>
        <work-item-actions-split-button
          v-if="showAddButton"
          data-testid="create-options-dropdown"
          :actions="addItemsActions"
          :tooltip-text="__('Add development item')"
        />
      </template>

      <template v-if="isRelatedDevelopmentListEmpty && !error" #empty>
        {{ __('None') }}
      </template>

      <template #default>
        <gl-alert v-if="error" :dismissible="false" variant="danger">
          {{ error }}
        </gl-alert>
        <work-item-development-relationship-list
          v-if="!isRelatedDevelopmentListEmpty"
          :is-modal="isModal"
          :work-item-dev-widget="workItemDevelopment"
          :work-item-full-path="workItemFullPath"
          :work-item-iid="workItemIid"
          :can-create-merge-request="showAddButton"
        />
      </template>
    </crud-component>
    <work-item-create-branch-merge-request-modal
      v-if="!isLoading"
      :show-modal="showCreateBranchAndMrModal"
      :show-branch-flow="showBranchFlow"
      :show-merge-request-flow="showMergeRequestFlow"
      :work-item-iid="workItemIid"
      :work-item-id="workItemId"
      :work-item-type="workItemTypeName"
      :work-item-full-path="workItemFullPath"
      :is-confidential-work-item="isConfidentialWorkItem"
      :project-id="projectId"
      @hideModal="toggleCreateModal(false)"
      @fetchedPermissions="updatePermissions"
    />
  </div>
</template>

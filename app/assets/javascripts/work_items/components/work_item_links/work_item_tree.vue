<script>
import { GlAlert } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { createAlert } from '~/alert';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT,
  WORK_ITEM_TYPE_VALUE_MAP,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  WORK_ITEM_TYPE_ENUM_EPIC,
  CHILD_ITEMS_ANCHOR,
} from '../../constants';
import { findHierarchyWidgets, getDefaultHierarchyChildrenCount } from '../../utils';
import getWorkItemTreeQuery from '../../graphql/work_item_tree.query.graphql';
import WorkItemChildrenLoadMore from '../shared/work_item_children_load_more.vue';
import WorkItemMoreActions from '../shared/work_item_more_actions.vue';
import WorkItemActionsSplitButton from './work_item_actions_split_button.vue';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemChildrenWrapper from './work_item_children_wrapper.vue';
import WorkItemRolledUpData from './work_item_rolled_up_data.vue';

export default {
  FORM_TYPES,
  WORK_ITEMS_TREE_TEXT,
  WORK_ITEM_TYPE_ENUM_OBJECTIVE,
  WORK_ITEM_TYPE_ENUM_KEY_RESULT,
  components: {
    GlAlert,
    WorkItemActionsSplitButton,
    CrudComponent,
    WorkItemLinksForm,
    WorkItemChildrenWrapper,
    WorkItemChildrenLoadMore,
    WorkItemMoreActions,
    WorkItemRolledUpData,
  },
  inject: ['hasSubepicsFeature'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
    parentWorkItemType: {
      type: String,
      required: false,
      default: '',
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
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canUpdateChildren: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowedChildTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      error: undefined,
      formType: null,
      childType: null,
      widgetName: CHILD_ITEMS_ANCHOR,
      showLabels: true,
      fetchNextPageInProgress: false,
      workItem: {},
      disableContent: false,
    };
  },
  apollo: {
    hierarchyWidget: {
      query: getWorkItemTreeQuery,
      variables() {
        return {
          id: this.workItemId,
          pageSize: getDefaultHierarchyChildrenCount(),
          endCursor: '',
        };
      },
      skip() {
        return !this.workItemId;
      },
      update({ workItem = {} }) {
        const { children } = findHierarchyWidgets(workItem.widgets);
        this.$emit('childrenLoaded', Boolean(children?.count));
        this.workItem = workItem;
        return children || {};
      },
      error() {
        this.error = s__('WorkItems|An error occurred while fetching children');
      },
      result() {
        if (this.hasNextPage && this.children.length === 0) {
          this.fetchNextPage();
        }
      },
    },
  },
  computed: {
    childrenIds() {
      return this.children.map((c) => c.id);
    },
    addItemsActions() {
      let childTypes = this.allowedChildTypes;
      // To remove EPICS actions when subepics are not available
      if (
        this.workItemType.toUpperCase() === WORK_ITEM_TYPE_ENUM_EPIC &&
        !this.hasSubepicsFeature
      ) {
        childTypes = childTypes.filter((type) => {
          return type.name.toUpperCase() !== WORK_ITEM_TYPE_ENUM_EPIC;
        });
      }

      const reorderedChildTypes = childTypes.slice().sort((a, b) => a.id.localeCompare(b.id));
      return reorderedChildTypes.map((type) => {
        const enumType = WORK_ITEM_TYPE_VALUE_MAP[type.name];
        return {
          name: WORK_ITEMS_TYPE_MAP[enumType].name,
          items: this.genericActionItems(type.name).map((item) => ({
            text: item.title,
            action: item.action,
          })),
        };
      });
    },
    children() {
      return this.hierarchyWidget?.nodes || [];
    },
    isLoadingChildren() {
      return this.$apollo.queries.hierarchyWidget.loading;
    },
    showEmptyMessage() {
      return this.children.length === 0 && !this.isLoadingChildren;
    },
    pageInfo() {
      return this.hierarchyWidget?.pageInfo;
    },
    endCursor() {
      return this.pageInfo?.endCursor || '';
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
    workItemNamespaceName() {
      return this.workItem?.namespace?.fullName;
    },
    shouldRolledUpWeightBeVisible() {
      return this.showRolledUpWeight && this.rolledUpWeight !== null;
    },
  },
  methods: {
    genericActionItems(workItem) {
      const enumType = WORK_ITEM_TYPE_VALUE_MAP[workItem];
      const workItemName = WORK_ITEMS_TYPE_MAP[enumType].name.toLowerCase();
      return [
        {
          title: sprintf(s__('WorkItem|New %{workItemName}'), { workItemName }),
          action: () => this.showAddForm(FORM_TYPES.create, enumType),
        },
        {
          title: sprintf(s__('WorkItem|Existing %{workItemName}'), { workItemName }),
          action: () => this.showAddForm(FORM_TYPES.add, enumType),
        },
      ];
    },
    showAddForm(formType, childType) {
      this.$refs.workItemTree.showForm();
      this.formType = formType;
      this.childType = childType;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.$refs.workItemTree.hideForm();
    },
    showModal({ event, child }) {
      this.$emit('show-modal', { event, modalWorkItem: child });
    },
    async fetchNextPage() {
      if (this.hasNextPage && !this.fetchNextPageInProgress) {
        this.fetchNextPageInProgress = true;
        try {
          await this.$apollo.queries.hierarchyWidget.fetchMore({
            variables: {
              endCursor: this.endCursor,
            },
          });
        } catch (error) {
          createAlert({
            message: s__('Hierarchy|Something went wrong while fetching children.'),
            captureError: true,
            error,
          });
        } finally {
          this.fetchNextPageInProgress = false;
        }
      }
    },
  },
};
</script>

<template>
  <crud-component
    ref="workItemTree"
    :title="$options.WORK_ITEMS_TREE_TEXT.title"
    :anchor-id="widgetName"
    :count="childrenIds.length"
    icon="issue-type-task"
    :is-loading="isLoadingChildren && !fetchNextPageInProgress"
    is-collapsible
    data-testid="work-item-tree"
  >
    <template #count>
      <work-item-rolled-up-data
        :work-item-id="workItemId"
        :work-item-iid="workItemIid"
        :work-item-type="workItemType"
        :full-path="fullPath"
      />
    </template>

    <template #actions>
      <work-item-actions-split-button
        v-if="canUpdateChildren"
        :actions="addItemsActions"
        class="gl-mr-3"
      />
      <work-item-more-actions
        :work-item-iid="workItemIid"
        :full-path="fullPath"
        :work-item-type="workItemType"
        :show-labels="showLabels"
        show-view-roadmap-action
        @toggle-show-labels="showLabels = !showLabels"
      />
    </template>

    <template #form>
      <work-item-links-form
        ref="wiLinksForm"
        data-testid="add-tree-form"
        :full-path="fullPath"
        :full-name="workItemNamespaceName"
        :is-group="isGroup"
        :issuable-gid="workItemId"
        :work-item-iid="workItemIid"
        :form-type="formType"
        :parent-work-item-type="parentWorkItemType"
        :children-type="childType"
        :children-ids="childrenIds"
        :parent-confidential="confidential"
        @success="hideAddForm"
        @cancel="hideAddForm"
        @addChild="$emit('addChild')"
        @update-in-progress="disableContent = $event"
      />
    </template>

    <template v-if="showEmptyMessage" #empty>
      {{ $options.WORK_ITEMS_TREE_TEXT.empty }}
    </template>

    <template #default>
      <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
        {{ error }}
      </gl-alert>

      <work-item-children-wrapper
        :children="children"
        :parent="workItem"
        :can-update="canUpdateChildren"
        :full-path="fullPath"
        :work-item-id="workItemId"
        :work-item-iid="workItemIid"
        :work-item-type="workItemType"
        :show-labels="showLabels"
        :disable-content="disableContent"
        :allowed-child-types="allowedChildTypes"
        @error="error = $event"
        @show-modal="showModal"
      />
      <work-item-children-load-more
        v-if="hasNextPage"
        data-testid="work-item-load-more"
        class="gl-ml-4 gl-pl-1"
        :fetch-next-page-in-progress="fetchNextPageInProgress"
        @fetch-next-page="fetchNextPage"
      />
    </template>
  </crud-component>
</template>
